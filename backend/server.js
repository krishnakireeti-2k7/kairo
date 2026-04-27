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
  const oldestLog = logs[logs.length - 1];
  const newestLog = logs[0];
  const dateRangeDays =
    oldestLog && newestLog
      ? Math.ceil(
          (new Date(newestLog.timestamp) - new Date(oldestLog.timestamp)) /
            (1000 * 60 * 60 * 24)
        )
      : 0;

  const prompt = `
Return valid JSON only. No markdown fences.

Schema:
{
  "patient_summary": "string — 2-3 sentence clinical overview written in third person e.g. 'The patient has reported...'",
  "presenting_symptoms": ["string — each as a clinical one-liner"],
  "symptom_analysis": [
    {
      "symptom": "string",
      "frequency": "string e.g. '4 occurrences in 30 days'",
      "avg_severity": "string e.g. '6.2 / 10'",
      "trend": "string e.g. 'worsening', 'stable', 'improving'",
      "notes": "string — clinical observation about this symptom"
    }
  ],
  "patterns_identified": ["string — each a clinical pattern observation"],
  "trigger_correlations": ["string — each a noted trigger-symptom correlation, or state 'Insufficient data' if not determinable"],
  "discussion_points": ["string — specific things the patient should raise with their doctor"],
  "data_confidence": {
    "level": "string — one of: 'High (15+ logs)', 'Moderate (7–14 logs)', 'Low (3–6 logs)', 'Insufficient (<3 logs)'",
    "log_count": number,
    "date_range_days": number,
    "caveat": "string — plain English note about what the limited data means for reliability of this report"
  }
}

You are generating a medical-grade symptom history report for a clinician to review.
Use clinical but readable language. Write in third person where appropriate.
Do NOT diagnose, name specific diseases as conclusions, prescribe treatment, or imply certainty beyond the data.
Describe observations, symptom patterns, and discussion points only.

Populate data_confidence honestly using the provided log count and date range.
If log count is under 3, use "Insufficient (<3 logs)".
If log count is 3 to 6, use "Low (3–6 logs)".
If log count is 7 to 14, use "Moderate (7–14 logs)".
If log count is 15 or more, use "High (15+ logs)".
For limited datasets, the caveat must clearly explain that patterns and trends may not be statistically representative.
For example, if only 3 logs exist over 1 day, say this report is based on only 3 data points collected over 1 day, patterns may not be statistically representative, and continued logging over 2–4 weeks will improve report accuracy.
If trigger correlations cannot be inferred from the logs, return ["Insufficient data"].

Stats:
- Total logs: ${stats.totalLogs}
- Average severity: ${stats.averageSeverity.toFixed(1)}
- Most frequent symptom: ${stats.mostFrequentSymptom}
- Frequency: ${stats.mostFrequentCount}
- Date range days: ${dateRangeDays}

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
    patient_summary:
      typeof parsed.patient_summary === 'string' &&
      parsed.patient_summary.trim().length > 0
        ? parsed.patient_summary.trim()
        : 'No clinical summary available from the submitted logs.',
    presenting_symptoms: sanitizeStringArray(parsed.presenting_symptoms),
    symptom_analysis: Array.isArray(parsed.symptom_analysis)
      ? parsed.symptom_analysis
          .filter((item) => item && typeof item === 'object')
          .map((item) => ({
            symptom: sanitizeString(item.symptom, 'Unspecified symptom'),
            frequency: sanitizeString(item.frequency, 'Not specified'),
            avg_severity: sanitizeString(item.avg_severity, 'Not specified'),
            trend: sanitizeString(item.trend, 'Not specified'),
            notes: sanitizeString(item.notes, 'No additional notes provided.'),
          }))
      : [],
    patterns_identified: sanitizeStringArray(parsed.patterns_identified),
    trigger_correlations: sanitizeStringArray(parsed.trigger_correlations),
    discussion_points: sanitizeStringArray(parsed.discussion_points),
    data_confidence: {
      level: sanitizeString(
        parsed.data_confidence?.level,
        getDataConfidenceLevel(logs.length)
      ),
      log_count:
        typeof parsed.data_confidence?.log_count === 'number'
          ? parsed.data_confidence.log_count
          : logs.length,
      date_range_days:
        typeof parsed.data_confidence?.date_range_days === 'number'
          ? parsed.data_confidence.date_range_days
          : dateRangeDays,
      caveat: sanitizeString(
        parsed.data_confidence?.caveat,
        buildDataConfidenceCaveat(logs.length, dateRangeDays)
      ),
    },
  };
}

async function buildReportPdf({ insights, logs, stats }) {
  return new Promise((resolve, reject) => {
    const margins = {
      top: 60,
      bottom: 60,
      left: 65,
      right: 65,
    };
    const doc = new PDFDocument({
      size: 'A4',
      margins,
      bufferPages: true,
    });
    const chunks = [];
    const reportUuid = uuidv4();
    const generatedAt = new Date();
    const colors = {
      body: '#000000',
      heading: '#2C2C2C',
      subtext: '#555555',
      rule: '#CCCCCC',
      footnote: '#AAAAAA',
      header: '#1A3A5C',
      warning: '#B00020',
      white: '#FFFFFF',
    };

    doc.on('data', (chunk) => chunks.push(chunk));
    doc.on('end', () => resolve(Buffer.concat(chunks)));
    doc.on('error', reject);

    drawReportHeader(doc, {
      colors,
      generatedAt,
      reportId: reportUuid.slice(0, 8),
    });

    addParagraphSection(doc, colors, 'PATIENT SUMMARY', [
      insights.patient_summary,
    ]);
    addBulletSection(doc, colors, 'PRESENTING SYMPTOMS', insights.presenting_symptoms);
    addSymptomAnalysisSection(doc, colors, insights.symptom_analysis);
    addStatisticalOverviewSection(doc, colors, logs, stats);
    addBulletSection(
      doc,
      colors,
      'PATTERNS IDENTIFIED',
      insights.patterns_identified
    );
    addBulletSection(
      doc,
      colors,
      'TRIGGER CORRELATIONS',
      insights.trigger_correlations
    );
    addNumberedSection(
      doc,
      colors,
      'DISCUSSION POINTS FOR HEALTHCARE PROVIDER',
      insights.discussion_points
    );
    addDataConfidenceSection(doc, colors, insights.data_confidence);

    addFooters(doc, colors);

    doc.end();
  });
}

function drawReportHeader(doc, { colors, generatedAt, reportId }) {
  const pageWidth = doc.page.width;
  const blockHeight = 90;

  doc.rect(0, 0, pageWidth, blockHeight).fill(colors.header);

  doc
    .fillColor(colors.white)
    .font('Helvetica-Bold')
    .fontSize(18)
    .text('KAIRO HEALTH REPORT', 65, 24, { width: 300 });
  doc
    .font('Helvetica-Oblique')
    .fontSize(11)
    .text('Symptom History & Clinical Summary', 65, 49, { width: 300 });

  doc
    .font('Helvetica')
    .fontSize(9)
    .text(`Generated: ${formatReportDate(generatedAt)}`, 365, 26, {
      width: 165,
      align: 'right',
    })
    .text(`Report ID: ${reportId}`, 365, 42, {
      width: 165,
      align: 'right',
    });

  doc
    .fillColor(colors.subtext)
    .font('Helvetica-Oblique')
    .fontSize(8)
    .text(
      'This document was auto-generated by Kairo. It is not a medical diagnosis.',
      65,
      100,
      { width: getContentWidth(doc) }
    );

  doc.y = 125;
}

function addSectionHeading(doc, colors, heading) {
  ensureSpace(doc, 52);
  doc
    .fillColor(colors.heading)
    .font('Helvetica-Bold')
    .fontSize(12)
    .text(heading, doc.page.margins.left, doc.y, {
      width: getContentWidth(doc),
    });

  doc
    .moveTo(doc.page.margins.left, doc.y + 4)
    .lineTo(doc.page.width - doc.page.margins.right, doc.y + 4)
    .lineWidth(0.5)
    .strokeColor(colors.rule)
    .stroke();
  doc.moveDown(0.8);
}

function addParagraphSection(doc, colors, heading, paragraphs) {
  addSectionHeading(doc, colors, heading);
  const safeParagraphs =
    paragraphs && paragraphs.length ? paragraphs : ['No data available.'];

  for (const paragraph of safeParagraphs) {
    doc
      .fillColor(colors.body)
      .font('Helvetica')
      .fontSize(10)
      .text(paragraph, {
        width: getContentWidth(doc),
        lineGap: 5,
      });
    doc.moveDown(0.45);
  }

  doc.moveDown(0.8);
}

function addBulletSection(doc, colors, heading, items) {
  addSectionHeading(doc, colors, heading);
  const safeItems = items && items.length ? items : ['No data available.'];

  for (const item of safeItems) {
    addBullet(doc, colors, item, 10);
  }

  doc.moveDown(0.9);
}

function addSymptomAnalysisSection(doc, colors, symptoms) {
  addSectionHeading(doc, colors, 'SYMPTOM ANALYSIS');
  const safeSymptoms =
    symptoms && symptoms.length
      ? symptoms
      : [
          {
            symptom: 'No symptom analysis available',
            frequency: 'Not specified',
            avg_severity: 'Not specified',
            trend: 'Not specified',
            notes: 'Additional logs are needed for symptom-level analysis.',
          },
        ];

  for (const [index, symptom] of safeSymptoms.entries()) {
    ensureSpace(doc, 94);
    const startX = doc.page.margins.left;
    const labelX = startX + 12;
    const valueX = startX + 120;
    const rowGap = 14;

    doc
      .fillColor(colors.body)
      .font('Helvetica-Bold')
      .fontSize(10)
      .text(titleCase(symptom.symptom), startX, doc.y, {
        width: getContentWidth(doc),
      });
    doc.moveDown(0.35);

    const rows = [
      ['Frequency', symptom.frequency],
      ['Avg. Severity', symptom.avg_severity],
      ['Trend', symptom.trend],
    ];

    for (const [label, value] of rows) {
      const y = doc.y;
      doc
        .fillColor(colors.subtext)
        .font('Helvetica')
        .fontSize(9)
        .text(label, labelX, y, { width: 95 });
      doc
        .fillColor(colors.body)
        .font('Helvetica')
        .fontSize(9.5)
        .text(value, valueX, y, { width: getContentWidth(doc) - 120 });
      doc.y = y + rowGap;
    }

    doc
      .fillColor(colors.subtext)
      .font('Helvetica-Oblique')
      .fontSize(9)
      .text(symptom.notes, labelX, doc.y + 2, {
        width: getContentWidth(doc) - 24,
        lineGap: 3,
      });
    doc.moveDown(0.45);

    if (index < safeSymptoms.length - 1) {
      doc
        .moveTo(startX, doc.y + 2)
        .lineTo(doc.page.width - doc.page.margins.right, doc.y + 2)
        .lineWidth(0.35)
        .strokeColor(colors.rule)
        .stroke();
      doc.moveDown(0.7);
    }
  }

  doc.moveDown(0.8);
}

function addStatisticalOverviewSection(doc, colors, logs, stats) {
  const { oldestLog, newestLog, dateRangeDays } = getLogDateRange(logs);
  const dateRange =
    oldestLog && newestLog
      ? `${formatShortDate(oldestLog.timestamp)} to ${formatShortDate(
          newestLog.timestamp
        )}`
      : 'No dated logs available';
  const overview = [
    `Total logs reviewed: ${stats.totalLogs}`,
    `Date range covered: ${dateRange}`,
    `Most frequent symptom: ${titleCase(stats.mostFrequentSymptom)} (${stats.mostFrequentCount})`,
    `Average severity across all logs: ${stats.averageSeverity.toFixed(1)} / 10`,
    `Observation period: ${dateRangeDays} ${dateRangeDays === 1 ? 'day' : 'days'}`,
  ];

  addParagraphSection(doc, colors, 'STATISTICAL OVERVIEW', overview);
}

function addNumberedSection(doc, colors, heading, items) {
  addSectionHeading(doc, colors, heading);
  const safeItems = items && items.length ? items : ['No data available.'];

  safeItems.forEach((item, index) => {
    ensureSpace(doc, 34);
    const x = doc.page.margins.left;
    const y = doc.y;
    doc
      .fillColor(colors.body)
      .font('Helvetica-Bold')
      .fontSize(11)
      .text(`${index + 1}.`, x, y, { width: 24 });
    doc
      .font('Helvetica')
      .fontSize(11)
      .text(item, x + 26, y, {
        width: getContentWidth(doc) - 26,
        lineGap: 4,
      });
    doc.moveDown(0.55);
  });

  doc.moveDown(0.8);
}

function addDataConfidenceSection(doc, colors, dataConfidence) {
  const confidence = dataConfidence || {};
  const logCount =
    typeof confidence.log_count === 'number' ? confidence.log_count : 0;

  addSectionHeading(doc, colors, 'DATA CONFIDENCE & REPORT LIMITATIONS');
  doc
    .fillColor(colors.body)
    .font('Helvetica-Bold')
    .fontSize(10)
    .text(`Data Confidence: ${confidence.level || getDataConfidenceLevel(logCount)}`, {
      width: getContentWidth(doc),
      lineGap: 5,
    });
  doc.moveDown(0.35);

  doc
    .fillColor(colors.subtext)
    .font('Helvetica-Oblique')
    .fontSize(9.5)
    .text(
      confidence.caveat ||
        buildDataConfidenceCaveat(logCount, confidence.date_range_days || 0),
      {
        width: getContentWidth(doc),
        lineGap: 4,
      }
    );
  doc.moveDown(0.45);

  doc
    .fillColor(colors.footnote)
    .font('Helvetica')
    .fontSize(8.5)
    .text(
      '* Statistical patterns require a minimum of 14 logs over 14 days for clinical relevance. This report should be reviewed alongside a full patient history.',
      {
        width: getContentWidth(doc),
        lineGap: 3,
      }
    );

  if (logCount < 7) {
    doc.moveDown(0.3);
    doc
      .fillColor(colors.warning)
      .font('Helvetica')
      .fontSize(8.5)
      .text(
        '* Warning: Insufficient data for reliable trend analysis. Patterns shown are preliminary only.',
        {
          width: getContentWidth(doc),
          lineGap: 3,
        }
      );
  }
}

function addBullet(doc, colors, item, fontSize) {
  ensureSpace(doc, 30);
  const x = doc.page.margins.left;
  const y = doc.y;

  doc
    .fillColor(colors.body)
    .font('Helvetica')
    .fontSize(fontSize)
    .text('•', x, y, { width: 12 });
  doc.text(item, x + 16, y, {
    width: getContentWidth(doc) - 16,
    lineGap: 5,
  });
  doc.moveDown(0.45);
}

function addFooters(doc, colors) {
  const range = doc.bufferedPageRange();

  for (let i = range.start; i < range.start + range.count; i++) {
    doc.switchToPage(i);

    const footerY = doc.page.height - 42;
    doc
      .moveTo(doc.page.margins.left, footerY)
      .lineTo(doc.page.width - doc.page.margins.right, footerY)
      .lineWidth(0.4)
      .strokeColor(colors.rule)
      .stroke();

    doc
      .fillColor(colors.subtext)
      .font('Helvetica')
      .fontSize(8)
      .text('Kairo Health — Confidential Patient Document', doc.page.margins.left, footerY + 10, {
        width: 250,
      })
      .text(`Page ${i + 1} of ${range.count}`, doc.page.width - doc.page.margins.right - 90, footerY + 10, {
        width: 90,
        align: 'right',
      });
  }
}

function ensureSpace(doc, height) {
  const bottom = doc.page.height - doc.page.margins.bottom - 46;
  if (doc.y + height > bottom) {
    doc.addPage();
  }
}

function getContentWidth(doc) {
  return doc.page.width - doc.page.margins.left - doc.page.margins.right;
}

function getLogDateRange(logs) {
  const oldestLog = logs[logs.length - 1];
  const newestLog = logs[0];
  const dateRangeDays =
    oldestLog && newestLog
      ? Math.ceil(
          (new Date(newestLog.timestamp) - new Date(oldestLog.timestamp)) /
            (1000 * 60 * 60 * 24)
        )
      : 0;

  return {
    oldestLog,
    newestLog,
    dateRangeDays,
  };
}

function formatReportDate(date) {
  return date.toLocaleDateString('en-US', {
    year: 'numeric',
    month: 'short',
    day: '2-digit',
  });
}

function formatShortDate(value) {
  return new Date(value).toLocaleDateString('en-US', {
    year: 'numeric',
    month: 'short',
    day: '2-digit',
  });
}

function sanitizeString(value, fallback) {
  return typeof value === 'string' && value.trim().length > 0
    ? value.trim()
    : fallback;
}

function sanitizeStringArray(value) {
  return Array.isArray(value)
    ? value
        .filter((item) => typeof item === 'string' && item.trim().length > 0)
        .map((item) => item.trim())
    : [];
}

function getDataConfidenceLevel(logCount) {
  if (logCount >= 15) return 'High (15+ logs)';
  if (logCount >= 7) return 'Moderate (7–14 logs)';
  if (logCount >= 3) return 'Low (3–6 logs)';
  return 'Insufficient (<3 logs)';
}

function buildDataConfidenceCaveat(logCount, dateRangeDays) {
  return `This report is based on ${logCount} ${
    logCount === 1 ? 'data point' : 'data points'
  } collected over ${dateRangeDays} ${
    dateRangeDays === 1 ? 'day' : 'days'
  }. Patterns and trends identified may not be statistically representative. Continued logging over 2–4 weeks will improve report accuracy.`;
}

function titleCase(value) {
  if (!value) {
    return value;
  }

  return value.charAt(0).toUpperCase() + value.slice(1);
}

function getReportStoragePath(fileUrl) {
  try {
    const url = new URL(fileUrl);
    const marker = '/storage/v1/object/public/reports/';
    const index = url.pathname.indexOf(marker);

    if (index === -1) {
      return null;
    }

    return decodeURIComponent(url.pathname.slice(index + marker.length));
  } catch (_err) {
    return null;
  }
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
        name: 'Health Report',
        file_url: publicUrl,
        is_starred: false,
      })
      .select('id, name, file_url, created_at, is_starred')
      .single();

    if (reportError) {
      return res.status(500).json({
        error: 'Failed to save report metadata',
        details: reportError.message,
      });
    }

    return res.status(201).json({
      id: report.id,
      name: report.name || 'Health Report',
      url: report.file_url,
      created_at: report.created_at,
      is_starred: Boolean(report.is_starred),
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
      .select('id, name, file_url, created_at, is_starred')
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

app.patch('/reports/:id', authenticateRequest, async (req, res) => {
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

    const updates = {};
    if (Object.prototype.hasOwnProperty.call(req.body, 'name')) {
      const name = String(req.body.name || '').trim();
      if (!name) {
        return res.status(400).json({
          error: 'Report name cannot be empty',
        });
      }
      updates.name = name;
    }

    if (Object.prototype.hasOwnProperty.call(req.body, 'is_starred')) {
      updates.is_starred = Boolean(req.body.is_starred);
    }

    if (!Object.keys(updates).length) {
      return res.status(400).json({
        error: 'No valid report updates provided',
      });
    }

    const { data: report, error } = await supabaseAdmin
      .from('reports')
      .update(updates)
      .eq('id', req.params.id)
      .eq('user_id', user.id)
      .select('id, name, file_url, created_at, is_starred')
      .single();

    if (error) {
      return res.status(500).json({
        error: 'Failed to update report',
        details: error.message,
      });
    }

    return res.json({
      id: report.id,
      name: report.name || 'Health Report',
      url: report.file_url,
      created_at: report.created_at,
      is_starred: Boolean(report.is_starred),
    });
  } catch (err) {
    return res.status(500).json({
      error: 'Failed to update report',
      details: err.message,
    });
  }
});

app.delete('/reports/:id', authenticateRequest, async (req, res) => {
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

    const { data: report, error: fetchError } = await supabaseAdmin
      .from('reports')
      .select('id, file_url')
      .eq('id', req.params.id)
      .eq('user_id', user.id)
      .single();

    if (fetchError || !report) {
      return res.status(404).json({
        error: 'Report not found',
        details: fetchError?.message,
      });
    }

    const storagePath = getReportStoragePath(report.file_url);
    if (storagePath) {
      const { error: storageError } = await supabaseAdmin.storage
        .from('reports')
        .remove([storagePath]);

      if (storageError) {
        return res.status(500).json({
          error: 'Failed to delete report file',
          details: storageError.message,
        });
      }
    }

    const { error: deleteError } = await supabaseAdmin
      .from('reports')
      .delete()
      .eq('id', req.params.id)
      .eq('user_id', user.id);

    if (deleteError) {
      return res.status(500).json({
        error: 'Failed to delete report metadata',
        details: deleteError.message,
      });
    }

    return res.json({ ok: true });
  } catch (err) {
    return res.status(500).json({
      error: 'Failed to delete report',
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
