require('dotenv').config();

const express = require('express');
const cors = require('cors');
const { createClient } = require('@supabase/supabase-js');
const { GoogleGenerativeAI } = require('@google/generative-ai'); // ✅ correct SDK

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
const genAI = new GoogleGenerativeAI(GEMINI_API_KEY); // ✅ correct init
const chatModels = ['gemini-2.5-flash', 'gemini-1.5-flash-latest'];

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

/* ---------------- FORMAT LOGS ---------------- */
function formatLogsForPrompt(logs) {
  if (!logs.length) {
    return 'Logs:\n- No symptom logs found for this user.';
  }

  const lines = logs.map((log) => {
    const symptoms =
      Array.isArray(log.symptoms) && log.symptoms.length
        ? log.symptoms.join(', ')
        : 'No symptoms';

    return `- ${symptoms} (severity ${log.severity}, timestamp ${log.timestamp})`;
  });

  return `Logs:\n${lines.join('\n')}`;
}

function formatChatHistory(history) {
  if (!Array.isArray(history) || history.length === 0) {
    return 'No previous chat history.';
  }

  return history
    .slice(-10)
    .map((entry) => {
      const role = entry?.role === 'assistant' ? 'Assistant' : 'User';
      const content =
        typeof entry?.content === 'string' ? entry.content.trim() : '';

      return `${role}: ${content || '[empty]'}`;
    })
    .join('\n');
}

/* ---------------- GEMINI CALL ---------------- */
async function generateInsight(prompt) {
  try {
    console.log('Calling Gemini...');

    const model = genAI.getGenerativeModel({ model: 'gemini-2.5-flash' });  
    const result = await model.generateContent(prompt);
    const insight = result.response.text(); 

    if (!insight || !insight.trim()) {
      throw new Error('Empty response from Gemini');
    }

    return insight.trim();
  } catch (error) {
    console.error('Gemini error:', error.message);
    throw error;
  }
}

async function generateChatReply(prompt) {
  let lastError = null;

  for (const modelName of chatModels) {
    try {
      console.log('Calling chat model:', modelName);

      const model = genAI.getGenerativeModel({ model: modelName });
      const result = await model.generateContent(prompt);
      const reply = result.response.text();

      if (!reply || !reply.trim()) {
        throw new Error('Empty response from Gemini chat model');
      }

      return reply.trim();
    } catch (error) {
      lastError = error;
      console.error(`Chat model error for ${modelName}:`, error.message);

      const status = error?.status ?? error?.cause?.status;
      const message = error?.message ?? '';
      const isModelNotFound = status === 404 || message.includes('404');

      if (!isModelNotFound) {
        break;
      }
    }
  }

  throw lastError ?? new Error('Chat request failed.');
}

/* ---------------- MAIN ENDPOINT ---------------- */
app.post('/analyze', authenticateRequest, async (req, res) => {
  try {
    console.log('Fetching logs with user JWT...');

    const { data: logs, error } = await req.supabase
      .from('logs')
      .select('symptoms, severity, timestamp')
      .order('timestamp', { ascending: false });

    if (error) {
      console.error('Supabase query error:', error);
      return res.status(500).json({
        error: 'Supabase error',
        details: error.message,
      });
    }

    console.log('Fetched logs:', logs?.length || 0);

    const logSummary = formatLogsForPrompt(logs || []);

    const prompt = `
You are an intelligent health insights engine.

Given symptom logs, do NOT just say "not enough data".
Instead:
- Extract whatever signal is possible
- Make reasonable hypotheses
- Suggest what to track next

Be practical and actionable.

Format:
1. Key Observation
2. Possible Interpretation
3. What To Track Next
4. Actionable Advice

Keep it concise.

${logSummary}
`;

    const insight = await generateInsight(prompt);

    return res.status(200).json({ insight });
  } catch (error) {
    console.error('Analyze endpoint error:', error.message);

    return res.status(500).json({
      error: 'Gemini analysis failed',
      details: error.message,
    });
  }
});

app.post('/chat', authenticateRequest, async (req, res) => {
  try {
    const message =
      typeof req.body?.message === 'string' ? req.body.message.trim() : '';
    const history = Array.isArray(req.body?.history) ? req.body.history : [];

    if (!message) {
      return res.status(400).json({
        error: 'Missing message',
        details: 'Request body must include a non-empty message string.',
      });
    }

    console.log('Fetching logs for chat with user JWT...');

    const { data: logs, error } = await req.supabase
      .from('logs')
      .select('symptoms, severity, timestamp')
      .order('timestamp', { ascending: false })
      .limit(10);

    if (error) {
      console.error('Supabase chat query error:', error);
      return res.status(500).json({
        error: 'Supabase error',
        details: error.message,
      });
    }

    console.log('Fetched chat logs:', logs?.length || 0);

    const prompt = `
SYSTEM:
You are a health assistant with access to the user's symptom history.
Give concise, supportive, practical responses grounded in the user's logs.
Do not diagnose or claim certainty.

USER DATA:
${formatLogsForPrompt(logs || [])}

CHAT HISTORY:
${formatChatHistory(history)}

USER MESSAGE:
${message}
`;

    console.log('Chat prompt:', prompt);

    const reply = await generateChatReply(prompt);

    return res.status(200).json({ reply });
  } catch (error) {
    console.error('Chat endpoint error:', error.message);

    return res.status(500).json({
      error: 'Chat failed',
      details: error.message,
    });
  }
});

/* ---------------- HEALTH CHECK ---------------- */
app.get('/health', (_req, res) => {
  res.json({ ok: true });
});

/* ---------------- START SERVER ---------------- */
app.listen(port, () => {
  console.log(`Backend listening on http://localhost:${port}`);
});
