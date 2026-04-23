require('dotenv').config();

const express = require('express');
const cors = require('cors');
const { createClient } = require('@supabase/supabase-js');
const { GoogleGenerativeAI } = require('@google/generative-ai');

const app = express();
const port = Number(process.env.PORT || 3000);

app.use(cors());
app.use(express.json());

const { SUPABASE_URL, SUPABASE_ANON_KEY, GEMINI_API_KEY } = process.env;

if (!SUPABASE_URL || !SUPABASE_ANON_KEY || !GEMINI_API_KEY) {
  throw new Error(
    'Missing required environment variables: SUPABASE_URL, SUPABASE_ANON_KEY, GEMINI_API_KEY.'
  );
}

/* ---------------- GEMINI SETUP ---------------- */
const genAI = new GoogleGenerativeAI(GEMINI_API_KEY);

/* ---------------- AUTH MIDDLEWARE ---------------- */
function authenticateRequest(req, res, next) {
  const authHeader = req.headers.authorization || '';

  if (!authHeader.startsWith('Bearer ')) {
    return res.status(401).json({ error: 'Missing token' });
  }

  const token = authHeader.replace('Bearer ', '').trim();

  console.log('TOKEN LENGTH:', token.length);
  console.log('TOKEN PARTS:', token.split('.').length);

  if (token.split('.').length !== 3) {
    return res.status(401).json({ error: 'Invalid JWT format (token broken)' });
  }

  const supabaseUser = createClient(SUPABASE_URL, SUPABASE_ANON_KEY, {
    global: {
      headers: {
        Authorization: `Bearer ${token}`,
      },
    },
    auth: {
      persistSession: false,
      autoRefreshToken: false,
    },
  });

  req.supabase = supabaseUser;
  next();
}

/* ---------------- HELPERS ---------------- */

function formatLogsForPrompt(logs) {
  if (!logs.length) {
    return 'Logs:\n- No symptom logs found.';
  }

  return (
    'Logs:\n' +
    logs
      .map((log) => {
        const symptoms =
          Array.isArray(log.symptoms) && log.symptoms.length
            ? log.symptoms.join(', ')
            : 'No symptoms';

        return `- ${symptoms} (severity ${log.severity}, ${log.timestamp})`;
      })
      .join('\n')
  );
}

function formatChatHistory(messages) {
  if (!messages.length) return 'No previous chat.';

  return messages
    .map((m) =>
      m.role === 'assistant'
        ? `Assistant: ${m.content}`
        : `User: ${m.content}`
    )
    .join('\n');
}

/* ---------------- GEMINI ---------------- */

async function generateGeminiResponse(prompt) {
  try {
    console.log('Calling Gemini...');

    const model = genAI.getGenerativeModel({
      model: 'gemini-2.5-flash',
    });

    const result = await model.generateContent(prompt);
    const text = result.response.text();

    if (!text || !text.trim()) {
      throw new Error('Empty Gemini response');
    }

    return text.trim();
  } catch (err) {
    console.error('Gemini error:', err.message);
    throw err;
  }
}

/* ---------------- ANALYZE ---------------- */

app.post('/analyze', authenticateRequest, async (req, res) => {
  try {
    const { data: logs, error } = await req.supabase
      .from('logs')
      .select('symptoms, severity, timestamp')
      .order('timestamp', { ascending: false });

    if (error) {
      return res.status(500).json({
        error: 'Supabase error',
        details: error.message,
      });
    }

    const prompt = `
You are a health insights assistant.

Extract real value even from limited data.

${formatLogsForPrompt(logs || [])}
`;

    const insight = await generateGeminiResponse(prompt);

    res.json({ insight });
  } catch (err) {
    res.status(500).json({
      error: 'Analyze failed',
      details: err.message,
    });
  }
});

/* ---------------- CHAT (PERSISTENT) ---------------- */

app.post('/chat', authenticateRequest, async (req, res) => {
  try {
    const message =
      typeof req.body?.message === 'string' ? req.body.message.trim() : '';

    if (!message) {
      return res.status(400).json({
        error: 'Message required',
      });
    }

    /* -------- GET USER -------- */
    const {
      data: { user },
      error: userError,
    } = await req.supabase.auth.getUser();

    if (userError || !user) {
      return res.status(401).json({
        error: 'Invalid user',
      });
    }

    const userId = user.id;

    /* -------- SAVE USER MESSAGE -------- */
    await req.supabase.from('chat_messages').insert({
      user_id: userId,
      role: 'user',
      content: message,
    });

    /* -------- FETCH LOGS -------- */
    const { data: logs } = await req.supabase
      .from('logs')
      .select('symptoms, severity, timestamp')
      .eq('user_id', userId)
      .order('timestamp', { ascending: false })
      .limit(10);

    /* -------- FETCH CHAT HISTORY -------- */
    const { data: history } = await req.supabase
      .from('chat_messages')
      .select('role, content')
      .eq('user_id', userId)
      .order('created_at', { ascending: true })
      .limit(20);

    /* -------- BUILD PROMPT -------- */
    const prompt = `
SYSTEM:
You are a health assistant.
Use user logs + chat history.
Be practical, not generic.
Do NOT diagnose.

USER DATA:
${formatLogsForPrompt(logs || [])}

CHAT HISTORY:
${formatChatHistory(history || [])}

USER MESSAGE:
${message}
`;

    console.log('Chat prompt built');

    /* -------- GEMINI -------- */
    const reply = await generateGeminiResponse(prompt);

    /* -------- SAVE AI MESSAGE -------- */
    await req.supabase.from('chat_messages').insert({
      user_id: userId,
      role: 'assistant',
      content: reply,
    });

    return res.json({ reply });
  } catch (err) {
    console.error('Chat error:', err.message);

    return res.status(500).json({
      error: 'Chat failed',
      details: err.message,
    });
  }
});

app.get('/messages', authenticateRequest, async (req, res) => {
  try {
    const {
      data: { user },
      error: userError,
    } = await req.supabase.auth.getUser();

    if (userError || !user) {
      return res.status(401).json({
        error: 'Invalid user',
      });
    }

    const { data, error } = await req.supabase
      .from('chat_messages')
      .select('id, role, content, created_at')
      .eq('user_id', user.id)
      .order('created_at', { ascending: true });

    if (error) {
      return res.status(500).json({
        error: 'Failed to fetch messages',
        details: error.message,
      });
    }

    return res.json({ messages: data });
  } catch (err) {
    return res.status(500).json({
      error: 'Failed to fetch messages',
      details: err.message,
    });
  }
});

/* ---------------- HEALTH ---------------- */

app.get('/health', (_req, res) => {
  res.json({ ok: true });
});

/* ---------------- START ---------------- */

app.listen(port, () => {
  console.log(`Backend running on http://localhost:${port}`);
});
