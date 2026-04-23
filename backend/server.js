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

/* ---------------- HEALTH CHECK ---------------- */
app.get('/health', (_req, res) => {
  res.json({ ok: true });
});

/* ---------------- START SERVER ---------------- */
app.listen(port, () => {
  console.log(`Backend listening on http://localhost:${port}`);
});