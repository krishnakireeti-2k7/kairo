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
    'Missing required environment variables: SUPABASE_URL, SUPABASE_ANON_KEY, GEMINI_API_KEY.',
  );
}

const supabase = createClient(SUPABASE_URL, SUPABASE_ANON_KEY, {
  auth: {
    persistSession: false,
    autoRefreshToken: false,
  },
});

const genAI = new GoogleGenerativeAI(GEMINI_API_KEY);
const model = genAI.getGenerativeModel({ model: 'gemini-1.5-flash' });

function authenticateRequest(req, res, next) {
  const authHeader = req.headers.authorization || '';

  if (!authHeader.startsWith('Bearer ')) {
    return res.status(401).json({ error: 'Missing token' });
  }

  const token = authHeader.replace('Bearer ', '').trim();

  const supabaseUser = createClient(
    process.env.SUPABASE_URL,
    process.env.SUPABASE_ANON_KEY,
    {
      global: {
        headers: {
          Authorization: `Bearer ${token}`,
        },
      },
    }
  );

  req.supabase = supabaseUser;

  next();
}

function formatLogsForPrompt(logs) {
  if (!logs.length) {
    return 'Logs:\n- No symptom logs found for this user.';
  }

  const lines = logs.map((log) => {
    const symptoms = Array.isArray(log.symptoms) && log.symptoms.length
      ? log.symptoms.join(', ')
      : 'No symptoms';

    return `- ${symptoms} (severity ${log.severity}, timestamp ${log.timestamp})`;
  });

  return `Logs:\n${lines.join('\n')}`;
}

app.post('/analyze', authenticateRequest, async (req, res) => {
  try {
    console.log("Fetching logs with user JWT...");
    const { data: logs, error } = await req.supabase
        .from('logs')
        .select('symptoms, severity, timestamp')
        .order('timestamp', { ascending: false });

    if (error) {
      console.error('Supabase query error:', error);
      return res.status(500).json({ error: 'Failed to fetch logs.' });
    }

    const logSummary = formatLogsForPrompt(logs || []);
    const prompt = [
      'You are a health insights assistant. Analyze these logs and identify patterns, frequent symptoms, severity trends, and possible insights. Keep it concise and useful.',
      '',
      logSummary,
    ].join('\n');

    const result = await model.generateContent(prompt);
    const insight = result.response.text().trim();

    return res.json({ insight });
  } catch (error) {
    console.error('Analyze endpoint error:', error);
    return res.status(500).json({ error: 'Failed to analyze logs.' });
  }
});

app.get('/health', (_req, res) => {
  res.json({ ok: true });
});

app.listen(port, () => {
  console.log(`Backend listening on http://localhost:${port}`);
});
