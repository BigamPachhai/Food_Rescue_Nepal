import { Injectable, Logger } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import * as nodemailer from 'nodemailer';

@Injectable()
export class MailService {
  private readonly logger = new Logger(MailService.name);
  private transporter: nodemailer.Transporter;

  constructor(private configService: ConfigService) {
    this.transporter = nodemailer.createTransport({
      host: this.configService.get<string>('SMTP_HOST') || 'smtp.gmail.com',
      port: Number(this.configService.get<string>('SMTP_PORT') || 587),
      secure: false,
      pool: true,
      maxConnections: 3,
      auth: {
        user: this.configService.get<string>('SMTP_USER'),
        pass: this.configService.get<string>('SMTP_PASS'),
      },
      connectionTimeout: 10000,
      greetingTimeout: 10000,
      socketTimeout: 15000,
    });
  }

  async sendPasswordResetOtp(email: string, otp: string): Promise<void> {
    const from = this.configService.get<string>('SMTP_FROM') || this.configService.get<string>('SMTP_USER');

    await this.transporter.sendMail({
      from: `"Food Rescue Nepal" <${from}>`,
      to: email,
      subject: `${otp} – Your Food Rescue Nepal password reset code`,
      text: `Your password reset OTP is: ${otp}\n\nThis code expires in 15 minutes. Never share it with anyone.\n\nIf you didn't request a password reset, please ignore this email.`,
      html: `<!DOCTYPE html>
<html>
<head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"></head>
<body style="margin:0;padding:0;background:#f4f7f6;font-family:'Segoe UI',Arial,sans-serif;">
  <table width="100%" cellpadding="0" cellspacing="0" style="padding:40px 16px;">
    <tr><td align="center">
      <table width="100%" cellpadding="0" cellspacing="0" style="max-width:480px;background:#fff;border-radius:16px;overflow:hidden;box-shadow:0 4px 20px rgba(0,0,0,0.08);">
        <tr>
          <td style="background:linear-gradient(135deg,#2e7d32,#43a047);padding:28px 36px;text-align:center;">
            <p style="margin:0;color:#fff;font-size:22px;font-weight:700;">🍃 Food Rescue Nepal</p>
            <p style="margin:6px 0 0;color:rgba(255,255,255,0.8);font-size:13px;">Saving Food, Feeding Lives</p>
          </td>
        </tr>
        <tr>
          <td style="padding:32px 36px;">
            <h2 style="margin:0 0 12px;color:#1a1a1a;font-size:20px;">Reset Your Password</h2>
            <p style="margin:0 0 24px;color:#555;font-size:15px;line-height:1.6;">
              Use the code below to reset your password. It expires in <strong>15 minutes</strong>.
            </p>
            <div style="background:#f0fdf4;border:2px solid #43a047;border-radius:12px;padding:24px;text-align:center;margin-bottom:24px;">
              <p style="margin:0 0 6px;color:#666;font-size:12px;text-transform:uppercase;letter-spacing:1.5px;">One-Time Password</p>
              <p style="margin:0;color:#2e7d32;font-size:42px;font-weight:800;letter-spacing:12px;">${otp}</p>
            </div>
            <p style="margin:0;color:#999;font-size:13px;line-height:1.6;">
              If you didn't request a password reset, you can safely ignore this email. Your password will remain unchanged.
            </p>
          </td>
        </tr>
        <tr>
          <td style="background:#fafafa;padding:16px 36px;text-align:center;border-top:1px solid #f0f0f0;">
            <p style="margin:0;color:#bbb;font-size:12px;">© 2024 Food Rescue Nepal · Never share this code with anyone</p>
          </td>
        </tr>
      </table>
    </td></tr>
  </table>
</body>
</html>`,
    });

    this.logger.log(`Password reset OTP sent to ${email}`);
  }
}
