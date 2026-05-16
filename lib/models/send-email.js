const https = require('https');

function resendRequest(body) {
  const payload = JSON.stringify(body);
  return new Promise((resolve, reject) => {
    const req = https.request({
      hostname: 'api.resend.com',
      path: '/emails',
      method: 'POST',
      headers: {
        'Authorization': `Bearer ${process.env.RESEND_API_KEY}`,
        'Content-Type': 'application/json',
        'Content-Length': Buffer.byteLength(payload),
      },
    }, (res) => {
      let data = '';
      res.on('data', c => data += c);
      res.on('end', () => resolve({ status: res.statusCode, body: JSON.parse(data) }));
    });
    req.on('error', reject);
    req.write(payload);
    req.end();
  });
}

module.exports = async function handler(req, res) {
  res.setHeader('Access-Control-Allow-Origin', '*');
  res.setHeader('Access-Control-Allow-Methods', 'POST, OPTIONS');
  res.setHeader('Access-Control-Allow-Headers', 'Content-Type');
  if (req.method === 'OPTIONS') return res.status(200).end();
  if (req.method !== 'POST') return res.status(405).json({ error: 'Method not allowed' });

  const { to, toName, subject, code } = req.body || {};
  if (!to || !code) return res.status(400).json({ error: 'Missing fields' });

  const html = `<!DOCTYPE html><html><body style="margin:0;padding:0;background:#f7f4ef;font-family:sans-serif">
  <table width="100%" cellpadding="0" cellspacing="0"><tr><td align="center" style="padding:40px 20px">
  <table width="480" cellpadding="0" cellspacing="0" style="background:#fff;border-radius:16px;overflow:hidden">
  <tr><td style="background:#1a1612;padding:28px 32px"><span style="color:#fff;font-size:18px;font-weight:800">⏱ ChaseIt</span></td></tr>
  <tr><td style="padding:36px 32px">
    <h1 style="margin:0 0 8px;font-size:24px;font-weight:800;color:#1a1612">Verify your email</h1>
    <p style="margin:0 0 24px;font-size:15px;color:#8a8070;line-height:1.6">Hi ${toName || 'there'}, enter this code in ChaseIt to activate your account.</p>
    <div style="background:#f7f4ef;border-radius:12px;padding:24px;text-align:center;margin:0 0 24px">
      <div style="font-size:44px;font-weight:800;letter-spacing:14px;color:#1a1612;font-family:monospace">${code}</div>
      <p style="margin:8px 0 0;font-size:12px;color:#8a8070">Expires in 10 minutes</p>
    </div>
    <p style="margin:0;font-size:13px;color:#c4bdb0">If you did not sign up, ignore this email.</p>
  </td></tr>
  <tr><td style="background:#f7f4ef;padding:20px 32px;border-top:1px solid #f0ece5">
    <p style="margin:0;font-size:12px;color:#c4bdb0;text-align:center">© 2026 ChaseIt · Invoice Automation</p>
  </td></tr>
  </table></td></tr></table></body></html>`;

  try {
    const result = await resendRequest({
      from: process.env.EMAIL_FROM || 'ChaseIt <noreply@resend.dev>',
      to: [to],
      subject: subject || 'Verify your ChaseIt account',
      html,
    });
    if (result.status !== 200 && result.status !== 201) {
      return res.status(result.status).json({ error: result.body?.message || 'Email failed' });
    }
    return res.status(200).json({ sent: true });
  } catch (err) {
    return res.status(500).json({ error: err.message });
  }
};
