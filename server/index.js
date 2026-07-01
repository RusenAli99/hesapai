const express = require('express');
const cors = require('cors');
const rateLimit = require('express-rate-limit');
const fetch = require('node-fetch');
require('dotenv').config();

const app = express();
const PORT = process.env.PORT || 3000;

// Enable CORS for all domains (especially Flutter Web)
app.use(cors());
app.use(express.json());

// Rate Limiting: Max 20 requests per minute from an IP
const limiter = rateLimit({
  windowMs: 1 * 60 * 1000, // 1 minute
  max: 20, // Limit each IP to 20 requests per windowMs
  message: { error: 'Çok fazla istek gönderdiniz. Lütfen bir dakika bekleyin.' }
});

app.use('/api/', limiter);

// API Endpoint to parse text using Gemini
app.post('/api/parse', async (req, res) => {
  const { text } = req.body;

  if (!text || text.trim().length === 0) {
    return res.status(400).json({ error: 'Metin boş olamaz.' });
  }

  const apiKey = process.env.GEMINI_API_KEY;
  if (!apiKey) {
    console.error("MISSING GEMINI_API_KEY environment variable.");
    return res.status(500).json({ error: 'Sunucu yapılandırma hatası: API Key bulunamadı.' });
  }

  // Current system date for reference
  const todayStr = new Date().toISOString().split('T')[0];

  const prompt = `You are an expert financial transaction parser. Analyze the following Turkish text and extract:
1. amount: the total money amount as a double (e.g. 450.0).
2. type: must be either 'income' or 'expense'.
3. category: must be one of [Maaş, Freelance, Yatırım, Diğer Gelir, Market, Yemek, Ulaşım, Yakıt, Fatura, Eğlence, Sağlık, Eğitim, Alışveriş, Diğer].
4. description: a short description of the transaction (in Turkish).
5. date: date of transaction in ISO format (default to today: ${todayStr}, but check if user mentions 'dün' - one day before, or 'geçen hafta').
6. isRecurring: true if the text indicates a recurring routine (e.g. 'her ay', 'aylık', 'haftalık', 'her yıl'), false otherwise.
7. recurringInterval: if isRecurring is true, must be one of [weekly, monthly, yearly], null otherwise.

Format the output as a valid JSON object ONLY with the keys: amount, type, category, description, date, isRecurring, recurringInterval. Do not include markdown formatting, markdown code blocks, or extra text.

User text: "${text}"`;

  try {
    const geminiUrl = `https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent?key=${apiKey}`;
    const response = await fetch(geminiUrl, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        contents: [{ parts: [{ text: prompt }] }],
        generationConfig: {
          responseMimeType: "application/json"
        }
      })
    });

    if (!response.ok) {
      const errText = await response.text();
      console.error("Gemini API Error:", errText);
      return res.status(502).json({ error: 'Gemini API ile iletişim kurulamadı.' });
    }

    const result = await response.json();
    const generatedText = result.candidates?.[0]?.content?.parts?.[0]?.text;

    if (!generatedText) {
      return res.status(500).json({ error: 'Gemini uygun bir yanıt üretemedi.' });
    }

    // Parse the JSON output from Gemini
    const parsedData = JSON.parse(generatedText.trim());
    console.log("Parsed transaction successfully:", parsedData);
    res.json(parsedData);
  } catch (error) {
    console.error("Error processing transaction:", error);
    res.status(500).json({ error: 'İşlem ayrıştırılırken sunucu hatası oluştu.' });
  }
});

// API Endpoint to get financial insights from Gemini
app.post('/api/insights', async (req, res) => {
  const { transactions, budgets } = req.body;

  const apiKey = process.env.GEMINI_API_KEY;
  if (!apiKey) {
    console.error("MISSING GEMINI_API_KEY environment variable.");
    return res.status(500).json({ error: 'Sunucu yapılandırma hatası: API Key bulunamadı.' });
  }

  // Format transactions and budgets for the prompt
  const txListStr = (transactions || [])
    .map(t => `- Tutar: ${t.amount} TL, Tip: ${t.type === 'income' ? 'Gelir' : 'Gider'}, Kategori: ${t.category}, Açıklama: ${t.description}, Tarih: ${t.date}`)
    .join('\n');

  const budgetStr = Object.entries(budgets || {})
    .map(([cat, limit]) => `- ${cat}: ${limit} TL bütçe limiti`)
    .join('\n');

  const prompt = `You are a friendly, expert personal finance coach. Analyze the following financial transactions and budget limits for the current month.
Write a personalized, concise summary of their spending habits, highlight any categories where they exceeded or are close to exceeding their budget, and provide 2-3 specific, actionable tips to save money in Turkish.
Address the user directly in a supportive, motivating tone. Use simple bullet points for formatting. Keep the response under 150 words.
Do not mention system details, API names, or technical details.

Harcamalar Listesi:
${txListStr || 'Henüz işlem bulunmuyor.'}

Tanımlanmış Aylık Bütçe Limitleri:
${budgetStr || 'Henüz bütçe tanımlanmamış.'}`;

  try {
    const geminiUrl = `https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent?key=${apiKey}`;
    const response = await fetch(geminiUrl, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        contents: [{ parts: [{ text: prompt }] }]
      })
    });

    if (!response.ok) {
      const errText = await response.text();
      console.error("Gemini API Error:", errText);
      return res.status(502).json({ error: 'Gemini API ile iletişim kurulamadı.' });
    }

    const result = await response.json();
    const generatedText = result.candidates?.[0]?.content?.parts?.[0]?.text;

    if (!generatedText) {
      return res.status(500).json({ error: 'Gemini uygun bir yanıt üretemedi.' });
    }

    console.log("Generated financial insights successfully.");
    res.json({ insights: generatedText.trim() });
  } catch (error) {
    console.error("Error generating insights:", error);
    res.status(500).json({ error: 'Rapor oluşturulurken sunucu hatası oluştu.' });
  }
});

app.listen(PORT, () => {
  console.log(`Gemini Proxy Server is running on port ${PORT}`);
});
