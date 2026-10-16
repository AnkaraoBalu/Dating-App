import {
  BadRequestException,
  Injectable,
  Logger,
  NotFoundException,
} from "@nestjs/common";
import { Prisma } from "@prisma/client";
import { PrismaService } from "../../database/prisma.service";
import { MailService } from "../mail/mail.service";
import { RealtimeService } from "../realtime/realtime.service";
import { ReportUserDto } from "./dto/report-user.dto";

type Pair = {
  meId: string;
  meName: string | null;
  targetId: string;
  targetName: string | null;
};

/**
 * Member safety: block, unmatch and report.
 *
 * Unmatch and block both end the connection for both people: their likes and
 * their conversation (with messages and calls) are removed. Unmatch records a
 * pass in both directions so neither is shown the other again; block keeps a
 * block record that also stops new likes and discovery in either direction.
 * A report is saved for review, emailed to the team inbox and blocks the
 * reported member for the reporter.
 */
@Injectable()
export class SafetyService {
  private readonly logger = new Logger(SafetyService.name);

  constructor(
    private readonly prisma: PrismaService,
    private readonly realtime?: RealtimeService,
    private readonly mail?: MailService,
  ) {}

  async block(clerkUserId: string, targetUserId: string) {
    const pair = await this.pair(clerkUserId, targetUserId);
    await this.prisma.$transaction(async (tx) => {
      await this.recordBlock(tx, pair);
      await this.endConnection(tx, pair);
    });
    this.notify(pair);
    return { blocked: true };
  }

  async unmatch(clerkUserId: string, targetUserId: string) {
    const pair = await this.pair(clerkUserId, targetUserId);
    await this.prisma.$transaction(async (tx) => {
      await this.endConnection(tx, pair);
      for (const [fromUserId, toUserId] of [
        [pair.meId, pair.targetId],
        [pair.targetId, pair.meId],
      ]) {
        await tx.profilePass.upsert({
          where: { fromUserId_toUserId: { fromUserId, toUserId } },
          create: { fromUserId, toUserId },
          update: {},
        });
      }
    });
    this.notify(pair);
    return { unmatched: true };
  }

  async report(clerkUserId: string, targetUserId: string, dto: ReportUserDto) {
    const pair = await this.pair(clerkUserId, targetUserId);
    const details = dto.details?.trim() || null;
    const report = await this.prisma.$transaction(async (tx) => {
      const created = await tx.profileReport.create({
        data: {
          reporterId: pair.meId,
          reportedUserId: pair.targetId,
          reason: dto.reason,
          details,
          source: dto.source ?? "profile",
        },
      });
      await this.recordBlock(tx, pair);
      await this.endConnection(tx, pair);
      return created;
    });
    this.notify(pair);
    await this.emailReport(pair, report);
    return { reported: true, blocked: true };
  }

  /** User ids blocked by, or blocking, [userId]. */
  static async blockedPeerIds(
    prisma: Pick<PrismaService, "profileBlock">,
    userId: string,
  ): Promise<string[]> {
    const blocks = await prisma.profileBlock.findMany({
      where: { OR: [{ blockerId: userId }, { blockedId: userId }] },
      select: { blockerId: true, blockedId: true },
    });
    return blocks.map((block) =>
      block.blockerId === userId ? block.blockedId : block.blockerId,
    );
  }

  private async pair(clerkUserId: string, targetUserId: string): Promise<Pair> {
    const [me, target] = await Promise.all([
      this.prisma.user.findUnique({
        where: { clerkUserId },
        select: { id: true, username: true },
      }),
      this.prisma.user.findUnique({
        where: { id: targetUserId },
        select: { id: true, username: true },
      }),
    ]);
    if (!me) throw new NotFoundException("User account was not found.");
    if (!target) throw new NotFoundException("Member not found.");
    if (me.id === target.id) {
      throw new BadRequestException("You cannot do this to your own profile.");
    }
    return {
      meId: me.id,
      meName: me.username,
      targetId: target.id,
      targetName: target.username,
    };
  }

  private async recordBlock(tx: Prisma.TransactionClient, pair: Pair) {
    await tx.profileBlock.upsert({
      where: {
        blockerId_blockedId: { blockerId: pair.meId, blockedId: pair.targetId },
      },
      create: { blockerId: pair.meId, blockedId: pair.targetId },
      update: {},
    });
  }

  /** Removes likes both ways and the pair's conversation (messages, calls). */
  private async endConnection(tx: Prisma.TransactionClient, pair: Pair) {
    await tx.profileLike.deleteMany({
      where: {
        OR: [
          { fromUserId: pair.meId, toUserId: pair.targetId },
          { fromUserId: pair.targetId, toUserId: pair.meId },
        ],
      },
    });
    const [userOneId, userTwoId] = [pair.meId, pair.targetId].sort();
    await tx.conversation.deleteMany({ where: { userOneId, userTwoId } });
  }

  /** Both members' open apps reload their matches and chats. */
  private notify(pair: Pair) {
    for (const userId of [pair.meId, pair.targetId]) {
      this.realtime?.notifyUser(userId, "inbox:changed", {});
    }
  }

  private async emailReport(
    pair: Pair,
    report: {
      id: string;
      reason: string;
      details: string | null;
      source: string;
      createdAt: Date;
    },
  ) {
    const to = this.mail?.teamInbox;
    if (!this.mail || !to) {
      this.logger.warn(
        `Report ${report.id} saved; no inbox configured for email.`,
      );
      return;
    }
    await this.mail.send({
      to,
      subject: `[Just2 report] ${report.reason} – ${pair.targetName ?? pair.targetId}`,
      text: [
        `Report ID: ${report.id}`,
        `Reason: ${report.reason}`,
        `Where: ${report.source}`,
        `Time: ${report.createdAt.toISOString()}`,
        "",
        `Reported member: ${pair.targetName ?? "(no name)"} (${pair.targetId})`,
        `Reported by: ${pair.meName ?? "(no name)"} (${pair.meId})`,
        "",
        "Details:",
        report.details ?? "(none)",
      ].join("\n"),
    });
  }
}
