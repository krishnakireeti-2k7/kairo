require('dotenv').config();

const express = require('express');
const cors = require('cors');
const { createClient } = require('@supabase/supabase-js');
const { GoogleGenerativeAI } = require('@google/generative-ai');
const PDFDocument = require('pdfkit');
const { v4: uuidv4 } = require('uuid');

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
const supabaseAdmin = createClient(
  SUPABASE_URL,
  process.env.SUPABASE_SERVICE_ROLE_KEY
);

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

function calculateReportStats(logs) {
  const totalLogs = logs.length;
  const averageSeverity = totalLogs
    ? logs.reduce((sum, log) => sum + Number(log.severity || 0), 0) / totalLogs
    : 0;

  const symptomCounts = new Map();
  for (const log of logs) {
    const symptoms =
      Array.isArray(log.symptoms) && log.symptoms.length
        ? log.symptoms
        : ['No symptoms'];

    for (const symptom of symptoms) {
      symptomCounts.set(symptom, (symptomCounts.get(symptom) || 0) + 1);
    }
  }

  let mostFrequentSymptom = 'No symptoms';
  let mostFrequentCount = 0;
  for (const [symptom, count] of symptomCounts.entries()) {
    if (count > mostFrequentCount) {
      mostFrequentSymptom = symptom;
      mostFrequentCount = count;
    }
  }

  return {
    totalLogs,
    averageSeverity,
    mostFrequentSymptom,
    mostFrequentCount,
  };
}

async function generateReportInsights(logs, stats) {
  const prompt = `
Return valid JSON only. No markdown fences.

Schema:
{
  "summary": "string",
  "patterns": ["string"],
  "recommendations": ["string"]
}

You are generating a concise health tracking report from symptom logs over the last 30 days.

Stats:
- Total logs: ${stats.totalLogs}
- Average severity: ${stats.averageSeverity.toFixed(1)}
- Most frequent symptom: ${stats.mostFrequentSymptom}
- Frequency: ${stats.mostFrequentCount}

Logs:
${formatLogsForPrompt(logs)}
`;

  const raw = await generateGeminiResponse(prompt);
  const normalized = raw
    .replace(/```json/gi, '')
    .replace(/```/g, '')
    .trim();

  const parsed = JSON.parse(normalized);

  return {
    summary:
        typeof parsed.summary === 'string' && parsed.summary.trim().length > 0
            ? parsed.summary.trim()
            : 'No summary available.',
    patterns: Array.isArray(parsed.patterns)
        ? parsed.patterns
            .filter((item) => typeof item === 'string' && item.trim().length > 0)
            .map((item) => item.trim())
        : [],
    recommendations: Array.isArray(parsed.recommendations)
        ? parsed.recommendations
            .filter((item) => typeof item === 'string' && item.trim().length > 0)
            .map((item) => item.trim())
        : [],
  };
}

function buildReportPdf({ insights, logs, stats }) {
  return new Promise((resolve, reject) => {
    const doc = new PDFDocument({
      margin: 50,
      size: 'A4',
    });
    const chunks = [];

    doc.on('data', (chunk) => chunks.push(chunk));
    doc.on('end', () => resolve(Buffer.concat(chunks)));
    doc.on('error', reject);

    doc.fontSize(22).font('Helvetica-Bold').text('KAIRO HEALTH REPORT');
    doc.moveDown(0.5);
    doc.fontSize(10).font('Helvetica').fillColor('#5B6775').text(
      `Generated on ${new Date().toLocaleString('en-US')}`,
    );
    doc.fillColor('#000000');
    doc.moveDown(1.2);

    addPdfSection(doc, 'Summary', [insights.summary]);
    addPdfSection(doc, 'Symptom Breakdown', [
      `Total logs: ${stats.totalLogs}`,
      `Most frequent symptom: ${titleCase(stats.mostFrequentSymptom)} (${stats.mostFrequentCount} ${stats.mostFrequentCount === 1 ? 'time' : 'times'})`,
    ]);
    addPdfSection(doc, 'Severity Analysis', [
      `Average severity: ${stats.averageSeverity.toFixed(1)} / 5`,
      `Recent entries reviewed: ${logs.length}`,
    ]);
    addPdfSection(doc, 'Patterns', insights.patterns);
    addPdfSection(doc, 'Recommendations', insights.recommendations);

    doc.end();
  });
}

function addPdfSection(doc, heading, lines) {
  doc.fontSize(15).font('Helvetica-Bold').text(heading);
  doc.moveDown(0.5);

  const safeLines = lines && lines.length ? lines : ['No data available.'];
  for (const line of safeLines) {
    doc
      .fontSize(11)
      .font('Helvetica')
      .fillColor('#1B1F24')
      .text(`• ${line}`, {
        lineGap: 4,
      });
  }

  doc.fillColor('#000000');
  doc.moveDown(1.1);
}

function titleCase(value) {
  if (!value) {
    return value;
  }

  return value.charAt(0).toUpperCase() + value.slice(1);
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

app.post('/generate-report', authenticateRequest, async (req, res) => {
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

    const threshold = new Date();
    threshold.setDate(threshold.getDate() - 30);

    const { data: logs, error: logsError } = await req.supabase
      .from('logs')
      .select('symptoms, severity, timestamp, duration')
      .eq('user_id', user.id)
      .gte('timestamp', threshold.toISOString())
      .order('timestamp', { ascending: false });

    if (logsError) {
      return res.status(500).json({
        error: 'Failed to fetch logs',
        details: logsError.message,
      });
    }

    const safeLogs = logs || [];
    const stats = calculateReportStats(safeLogs);
    const insights = await generateReportInsights(safeLogs, stats);
    const pdfBuffer = await buildReportPdf({
      insights,
      logs: safeLogs,
      stats,
    });

    const timestamp = new Date().toISOString().replace(/[:.]/g, '-');
    const filePath = `${user.id}/${timestamp}-${uuidv4()}.pdf`;

    const { error: uploadError } = await supabaseAdmin.storage
      .from('reports')
      .upload(filePath, pdfBuffer, {
        contentType: 'application/pdf',
        upsert: false,
      });

    if (uploadError) {
      return res.status(500).json({
        error: 'Failed to upload report',
        details: uploadError.message,
      });
    }

    const {
      data: { publicUrl },
    } = supabaseAdmin.storage.from('reports').getPublicUrl(filePath);

    const { data: report, error: reportError } = await supabaseAdmin
      .from('reports')
      .insert({
        user_id: user.id,
        file_url: publicUrl,
      })
      .select('id, file_url, created_at')
      .single();

    if (reportError) {
      return res.status(500).json({
        error: 'Failed to save report metadata',
        details: reportError.message,
      });
    }

    return res.status(201).json({
      id: report.id,
      url: report.file_url,
      created_at: report.created_at,
    });
  } catch (err) {
    return res.status(500).json({
      error: 'Report generation failed',
      details: err.message,
    });
  }
});

app.get('/reports', authenticateRequest, async (req, res) => {
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
      .from('reports')
      .select('id, file_url, created_at')
      .eq('user_id', user.id)
      .order('created_at', { ascending: false });

    if (error) {
      return res.status(500).json({
        error: 'Failed to fetch reports',
        details: error.message,
      });
    }

    return res.json({ reports: data || [] });
  } catch (err) {
    return res.status(500).json({
      error: 'Failed to fetch reports',
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
