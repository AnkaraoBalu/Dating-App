import { Injectable, Logger } from "@nestjs/common";
import { ConfigService } from "@nestjs/config";
import { createTransport, type Transporter } from "nodemailer";

export type MailMessage = { to: string; subject: string; text: string };

/** Sends plain-text mail through the configured SMTP account. */
@Injectable()
export class MailService {
  private readonly logger = new Logger(MailService.name);
  private transporter?: Transporter;

  constructor(private readonly config: ConfigService) {}

  /** The default team inbox for safety reports, if mail is configured. */
  get teamInbox(): string | undefined {
    return (
      this.config.get<string>("REPORTS_EMAIL_TO") ??
      this.config.get<string>("SMTP_USER")
    );
  }

  /** Best effort: returns false instead of throwing when mail cannot be sent. */
  async send(message: MailMessage): Promise<boolean> {
    const transporter = this.transport();
    if (!transporter) {
      this.logger.warn(
        `SMTP is not configured; not sending "${message.subject}".`,
      );
      return false;
    }
    try {
      await transporter.sendMail({
        from: `"Just2" <${this.config.get<string>("SMTP_USER")}>`,
        ...message,
      });
      return true;
    } catch (error) {
      this.logger.error(`Could not send "${message.subject}"`, error);
      return false;
    }
  }

  private transport(): Transporter | undefined {
    if (this.transporter) return this.transporter;
    const host = this.config.get<string>("SMTP_HOST");
    const user = this.config.get<string>("SMTP_USER");
    const pass = this.config.get<string>("SMTP_PASS");
    if (!host || !user || !pass) return undefined;
    const port = Number(this.config.get("SMTP_PORT") ?? 587);
    this.transporter = createTransport({
      host,
      port,
      secure: port === 465,
      auth: { user, pass },
    });
    return this.transporter;
  }
}
