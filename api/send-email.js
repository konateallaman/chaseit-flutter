module.exports = async function handler(req, res) {
  res.setHeader('Access-Control-Allow-Origin', '*');
  res.setHeader('Access-Control-Allow-Methods', 'POST, OPTIONS');
  res.setHeader('Access-Control-Allow-Headers', 'Content-Type');
  if (req.method === 'OPTIONS') return res.status(200).end();
  if (req.method !== 'POST') return res.status(405).json({ error: 'Method not allowed' });

  const { to, toName, code } = req.body || {};
  if (!to || !code) return res.status(400).json({ error: 'Missing fields' });

  const payload = JSON.stringify({
    from: process.env.EMAIL_FROM || 'ChaseIt <onboarding@resend.dev>',
    to: [to],
    subject: 'Verify your ChaseIt account',
    html: `<div style="font-family:sans-serif;max-width:480px;margin:0 auto;padding:40px 20px">
      <h1 style="color:#1a1612;font-size:24px">Verify your email</h1>
      <p style="color:#8a8070">Hi ${toName || 'there'}, enter this code in ChaseIt:</p>
      <div style="background:#f7f4ef;border-radius:12px;padding:24px;text-align:center;margin:20px 0">
        <div style="font-size:44px;font-weight:800;letter-spacing:14px;color:#1a1612;font-family:monospace">${code}</div>
        <p style="color:#8a8070;font-size:12px;margin:8px 0 0">Expires in 10 minutes</p>
      </div>
      <p style="color:#c4bdb0;font-size:13px">If you didn't sign up, ignore this email.</p>
    </div>`,
  });

  const https = require('https');
  const result = await new Promise((resolve, reject) => {
    const r = https.request({
      hostname: 'api.resend.com',
      path: '/emails',
      method: 'POST',
      headers: {
        'Authorization': `Bearer ${process.env.RESEND_API_KEY}`,
        'Content-Type': 'application/json',
        'Content-Length': Buffer.byteLength(payload),
      },
    }, (response) => {
      let data = '';
      response.on('data', c => data += c);
      response.on('end', () => resolve({ status: response.statusCode, body: data }));
    });
    r.on('error', reject);
    r.write(payload);
    r.end();
  });

  console.log('[send-email] Resend response:', result.status, result.body);
  return res.status(result.status === 200 || result.status === 201 ? 200 : 500)
    .json(JSON.parse(result.body));
};