import {
  BadRequestException,
  ConflictException,
  ForbiddenException,
  Injectable,
  NotFoundException,
} from "@nestjs/common";
import { Prisma, VibeGameSession } from "@prisma/client";
import { PrismaService } from "../../database/prisma.service";

type GameQuestion = { prompt: string; options: string[] };

const games: Record<string, { title: string; questions: GameQuestion[] }> = {
  this_or_that: {
    title: "This or That",
    questions: [
      {
        prompt: "What do you prefer for a weekend?",
        options: ["Beach getaway", "City exploration"],
      },
      {
        prompt: "Pick your perfect first date",
        options: ["Coffee and a walk", "Dinner and a show"],
      },
      {
        prompt: "Choose your evening mood",
        options: ["Live music", "Movie night"],
      },
      {
        prompt: "Your ideal mini adventure?",
        options: ["A new food spot", "A scenic drive"],
      },
      { prompt: "Choose a travel plan", options: ["Mountains", "Ocean"] },
      {
        prompt: "What sounds more fun?",
        options: ["Board games", "Arcade games"],
      },
      {
        prompt: "Pick a perfect Sunday",
        options: ["Slow brunch", "Spontaneous trip"],
      },
      {
        prompt: "One playlist for the road?",
        options: ["Indie favorites", "Old-school hits"],
      },
    ],
  },
  would_you_rather: {
    title: "Would You Rather?",
    questions: [
      {
        prompt: "What do you prefer for a weekend?",
        options: ["Beach getaway", "City exploration"],
      },
      {
        prompt: "Would you rather plan every detail or decide as you go?",
        options: ["Plan every detail", "Go with the flow"],
      },
      {
        prompt: "Choose a first-date setting",
        options: ["A cozy café", "A lively street market"],
      },
      {
        prompt: "Would you rather have more time or more travel?",
        options: ["A four-day weekend", "A new trip every month"],
      },
      {
        prompt: "Pick your ideal evening",
        options: ["Cook together", "Find a new restaurant"],
      },
      {
        prompt: "Would you rather be great at dancing or singing?",
        options: ["Dancing", "Singing"],
      },
      {
        prompt: "Choose a spontaneous plan",
        options: ["Catch a sunrise", "Take a late-night drive"],
      },
      {
        prompt:
          "Would you rather revisit a favorite place or explore somewhere new?",
        options: ["Revisit a favorite", "Explore somewhere new"],
      },
    ],
  },
  red_flag_green_flag: {
    title: "Red Flag / Green Flag",
    questions: [
      {
        prompt: "They are kind to service staff. Your call?",
        options: ["Green flag", "Red flag"],
      },
      {
        prompt: "They cancel plans at the last minute without explaining.",
        options: ["Green flag", "Red flag"],
      },
      {
        prompt: "They remember the little things you tell them.",
        options: ["Green flag", "Red flag"],
      },
      {
        prompt: "They expect you to share your location on every date.",
        options: ["Green flag", "Red flag"],
      },
      {
        prompt: "They can disagree without being disrespectful.",
        options: ["Green flag", "Red flag"],
      },
      {
        prompt: "They only talk about themselves on a first date.",
        options: ["Green flag", "Red flag"],
      },
      {
        prompt: "They are honest when they make a mistake.",
        options: ["Green flag", "Red flag"],
      },
      {
        prompt: "They pressure you to reply immediately every time.",
        options: ["Green flag", "Red flag"],
      },
    ],
  },
  guess_my_vibe: {
    title: "Guess My Vibe",
    questions: [
      {
        prompt: "Which vibe do you think the host brings to a trip?",
        options: ["The itinerary maker", "The spontaneous explorer"],
      },
      {
        prompt: "Pick the host's ideal recharge day",
        options: ["Quiet and cozy", "Out with friends"],
      },
      {
        prompt: "What would the host choose for a playlist?",
        options: ["Chill favorites", "Dance-floor hits"],
      },
      {
        prompt: "How does the host choose a restaurant?",
        options: ["A trusted favorite", "Somewhere totally new"],
      },
      {
        prompt: "What is the host's conversation style?",
        options: ["Deep talks", "Playful banter"],
      },
      {
        prompt: "Choose the host's ideal evening",
        options: ["Sunset outside", "Late-night city lights"],
      },
      {
        prompt: "What would the host bring on a road trip?",
        options: ["Snacks", "A perfect playlist"],
      },
      {
        prompt: "How does the host make weekend plans?",
        options: ["Book ahead", "See where the day goes"],
      },
    ],
  },
  two_truths_and_a_lie: {
    title: "Two Truths and a Lie",
    questions: [
      {
        prompt: "Which statement sounds most like your true story?",
        options: ["I have taken a solo trip", "I have never tried coffee"],
      },
      {
        prompt: "Pick the one you think is the lie",
        options: ["I can cook a great meal", "I have never watched a movie"],
      },
      {
        prompt: "Which would you believe about a new friend?",
        options: [
          "They once missed a flight",
          "They have never listened to music",
        ],
      },
      {
        prompt: "Choose the more believable travel story",
        options: ["I got lost in a new city", "I have visited every country"],
      },
      {
        prompt: "Which sounds like a real fun fact?",
        options: ["I learned a song in one day", "I have never laughed"],
      },
      {
        prompt: "Pick the story you would ask about",
        options: ["I met someone famous", "I have never used a phone"],
      },
      {
        prompt: "Which would you guess is true?",
        options: ["I can name every planet", "I have been to the moon"],
      },
      {
        prompt: "Choose the most believable little secret",
        options: ["I keep a travel journal", "I can read minds"],
      },
    ],
  },
  chemistry_check: {
    title: "Chemistry Check",
    questions: [
      {
        prompt: "Your ideal way to spend a free evening?",
        options: ["A relaxed night in", "A night out exploring"],
      },
      {
        prompt: "How do you like to communicate?",
        options: ["A thoughtful phone call", "Little messages through the day"],
      },
      {
        prompt: "Pick a shared weekend plan",
        options: ["Make something together", "Go somewhere new"],
      },
      {
        prompt: "What makes you feel appreciated?",
        options: ["Kind words", "Helpful little actions"],
      },
      {
        prompt: "Choose your conversation pace",
        options: ["One topic, deeply", "A little bit of everything"],
      },
      {
        prompt: "Pick a travel style",
        options: ["A comfortable plan", "An open itinerary"],
      },
      {
        prompt: "How do you like to celebrate?",
        options: ["A small meaningful moment", "A big shared experience"],
      },
      {
        prompt: "What matters most in a connection?",
        options: ["Easy laughter", "Honest conversations"],
      },
    ],
  },
};

function hasGame(gameType: string): boolean {
  return Object.prototype.hasOwnProperty.call(games, gameType);
}

const participantInclude = {
  user: {
    select: {
      id: true,
      firstName: true,
      lastName: true,
      username: true,
      imageUrl: true,
      profile: {
        select: {
          photos: {
            orderBy: { position: "asc" as const },
            take: 1,
            select: { secureUrl: true },
          },
        },
      },
    },
  },
  answers: { select: { questionIndex: true, choiceIndex: true } },
} satisfies Prisma.VibeGameParticipantInclude;

@Injectable()
export class VibeGameService {
  constructor(private readonly prisma: PrismaService) {}

  async active(clerkUserId: string, roomId: string) {
    const userId = await this.databaseUserId(clerkUserId);
    await this.assertRoomMember(userId, roomId);
    let session = await this.prisma.vibeGameSession.findFirst({
      where: { roomId, status: { in: ["waiting", "playing"] } },
      orderBy: { createdAt: "desc" },
    });
    if (
      session?.status === "waiting" &&
      Date.now() - session.createdAt.getTime() > 600_000
    ) {
      await this.prisma.vibeGameSession.updateMany({
        where: { id: session.id, status: "waiting" },
        data: {
          status: "cancelled",
          activeRoomId: null,
          finishedAt: new Date(),
        },
      });
      session = null;
    }
    if (session?.status === "playing") {
      await this.advanceIfReadyOrExpired(session);
      session = await this.getSession(session.id);
    }
    return session && ["waiting", "playing"].includes(session.status)
      ? this.state(session.id, userId)
      : null;
  }

  async stateFor(clerkUserId: string, sessionId: string) {
    const userId = await this.databaseUserId(clerkUserId);
    const session = await this.getSession(sessionId);
    await this.assertRoomMember(userId, session.roomId);
    if (session.status === "playing")
      await this.advanceIfReadyOrExpired(session);
    const participant = await this.prisma.vibeGameParticipant.findUnique({
      where: { sessionId_userId: { sessionId, userId } },
      select: { leftAt: true },
    });
    if (!participant || participant.leftAt)
      throw new ForbiddenException("Join this game to view it.");
    return this.state(sessionId, userId);
  }

  async create(
    clerkUserId: string,
    roomId: string,
    gameType: string,
    setup?: { statements?: string[]; lieIndex?: number },
  ) {
    const userId = await this.databaseUserId(clerkUserId);
    await this.assertRoomMember(userId, roomId);
    if (!hasGame(gameType))
      throw new BadRequestException("Choose a supported game.");
    if (gameType === "two_truths_and_a_lie") {
      const rawStatements: unknown = setup?.statements;
      if (
        !Array.isArray(rawStatements) ||
        !rawStatements.every((item) => typeof item === "string")
      ) {
        throw new BadRequestException(
          "Add three short statements for Two Truths and a Lie.",
        );
      }
      const statements = rawStatements.map((statement: string) =>
        statement.trim(),
      );
      if (
        statements.length !== 3 ||
        statements.some((statement) => !statement || statement.length > 120) ||
        new Set(statements.map((statement) => statement.toLocaleLowerCase()))
          .size !== 3
      ) {
        throw new BadRequestException(
          "Add three different, short statements for Two Truths and a Lie.",
        );
      }
      if (
        !Number.isInteger(setup?.lieIndex) ||
        setup!.lieIndex! < 0 ||
        setup!.lieIndex! > 2
      ) {
        throw new BadRequestException("Mark which statement is the lie.");
      }
      setup = { statements, lieIndex: setup!.lieIndex };
    }
    // Release an expired lobby or finish elapsed rounds before creating anew.
    await this.active(clerkUserId, roomId);
    const active = await this.prisma.vibeGameSession.findFirst({
      where: { activeRoomId: roomId },
      select: { id: true },
    });
    if (active)
      throw new ConflictException(
        "A game is already active in this room. Join it instead.",
      );
    let session: VibeGameSession;
    try {
      session = await this.prisma.vibeGameSession.create({
        data: {
          roomId,
          activeRoomId: roomId,
          hostUserId: userId,
          gameType,
          setup: setup ? (setup as Prisma.InputJsonValue) : Prisma.JsonNull,
          participants: { create: { userId } },
        },
      });
    } catch (error) {
      if (
        error instanceof Prisma.PrismaClientKnownRequestError &&
        error.code === "P2002"
      ) {
        throw new ConflictException(
          "A game just started in this room. Refresh to join it.",
        );
      }
      throw error;
    }
    return this.state(session.id, userId);
  }

  async join(clerkUserId: string, sessionId: string) {
    const userId = await this.databaseUserId(clerkUserId);
    let session = await this.getSession(sessionId);
    await this.assertRoomMember(userId, session.roomId);
    if (session.status !== "waiting" && session.status !== "playing") {
      throw new ConflictException("This game has already finished.");
    }
    if (session.status === "playing") {
      await this.advanceIfReadyOrExpired(session);
      session = await this.getSession(sessionId);
    }
    if (session.status !== "waiting" && session.status !== "playing") {
      throw new ConflictException("This game has already finished.");
    }
    await this.prisma.$transaction(async (tx) => {
      // Serialize joins so concurrent requests cannot exceed eight players.
      await tx.$queryRaw`SELECT id FROM "VibeGameSession" WHERE id = ${sessionId} FOR UPDATE`;
      const current = await tx.vibeGameSession.findUnique({
        where: { id: sessionId },
      });
      if (!current || !["waiting", "playing"].includes(current.status))
        throw new ConflictException("This game has already finished.");
      const existing = await tx.vibeGameParticipant.findUnique({
        where: { sessionId_userId: { sessionId, userId } },
      });
      if (existing && !existing.leftAt) return;
      const count = await tx.vibeGameParticipant.count({
        where: { sessionId, leftAt: null },
      });
      if (count >= session.maxPlayers)
        throw new ConflictException("This game is full.");
      await tx.vibeGameParticipant.upsert({
        where: { sessionId_userId: { sessionId, userId } },
        create: { sessionId, userId },
        update: { leftAt: null, joinedAt: new Date() },
      });
    });
    return this.state(sessionId, userId);
  }

  async start(clerkUserId: string, sessionId: string) {
    const userId = await this.databaseUserId(clerkUserId);
    const session = await this.getSession(sessionId);
    await this.assertRoomMember(userId, session.roomId);
    if (session.hostUserId !== userId)
      throw new ForbiddenException("Only the game host can start it.");
    if (session.status !== "waiting")
      throw new ConflictException("This game has already started.");
    const count = await this.prisma.vibeGameParticipant.count({
      where: { sessionId, leftAt: null },
    });
    if (count < 2)
      throw new BadRequestException(
        "Wait for at least one other player to join.",
      );
    const started = await this.prisma.vibeGameSession.updateMany({
      where: { id: sessionId, status: "waiting" },
      data: {
        status: "playing",
        startedAt: new Date(),
        questionDeadline: new Date(Date.now() + 45_000),
      },
    });
    if (started.count === 0)
      throw new ConflictException("This game has already started.");
    return this.state(sessionId, userId);
  }

  async answer(
    clerkUserId: string,
    sessionId: string,
    questionIndex: number,
    choiceIndex: number,
  ) {
    const userId = await this.databaseUserId(clerkUserId);
    let session = await this.getSession(sessionId);
    await this.assertRoomMember(userId, session.roomId);
    const participant = await this.prisma.vibeGameParticipant.findUnique({
      where: { sessionId_userId: { sessionId, userId } },
      select: { leftAt: true },
    });
    if (!participant || participant.leftAt)
      throw new ForbiddenException("Join this game before answering.");
    if (session.status === "playing") {
      await this.advanceIfReadyOrExpired(session);
      session = await this.getSession(sessionId);
    }
    const questions = this.questionsFor(session);
    if (session.status !== "playing")
      throw new ConflictException("The game is not accepting answers.");
    if (
      session.gameType === "two_truths_and_a_lie" &&
      session.hostUserId === userId
    )
      throw new ForbiddenException(
        "The host sets the lie; other players guess it.",
      );
    if (!Number.isInteger(questionIndex) || !Number.isInteger(choiceIndex))
      throw new BadRequestException("Choose one of the answers shown.");
    if (questionIndex !== session.questionIndex)
      throw new ConflictException(
        "That question has changed. The game was refreshed.",
      );
    if (
      choiceIndex < 0 ||
      choiceIndex >= questions[questionIndex]?.options.length
    ) {
      throw new BadRequestException("Choose one of the answers shown.");
    }
    try {
      await this.prisma.vibeGameAnswer.create({
        data: { sessionId, userId, questionIndex, choiceIndex },
      });
    } catch (error) {
      if (
        !(error instanceof Prisma.PrismaClientKnownRequestError) ||
        error.code !== "P2002"
      )
        throw error;
      const saved = await this.prisma.vibeGameAnswer.findUnique({
        where: {
          sessionId_userId_questionIndex: { sessionId, userId, questionIndex },
        },
      });
      if (saved?.choiceIndex !== choiceIndex) {
        throw new ConflictException(
          "Your answer is already locked for this question.",
        );
      }
    }
    await this.advanceIfReadyOrExpired(session);
    return this.state(sessionId, userId);
  }

  async leave(clerkUserId: string, sessionId: string) {
    const userId = await this.databaseUserId(clerkUserId);
    const session = await this.getSession(sessionId);
    await this.assertRoomMember(userId, session.roomId);
    await this.prisma.vibeGameParticipant.updateMany({
      where: { sessionId, userId, leftAt: null },
      data: { leftAt: new Date() },
    });
    const remaining = await this.prisma.vibeGameParticipant.findMany({
      where: { sessionId, leftAt: null },
      orderBy: { joinedAt: "asc" },
      select: { userId: true },
    });
    const hostDependent =
      session.gameType === "guess_my_vibe" ||
      session.gameType === "two_truths_and_a_lie";
    if (
      remaining.length === 0 ||
      (hostDependent && session.hostUserId === userId)
    ) {
      await this.prisma.vibeGameSession.updateMany({
        where: { id: sessionId, status: { in: ["waiting", "playing"] } },
        data: {
          status: "cancelled",
          activeRoomId: null,
          finishedAt: new Date(),
        },
      });
    } else if (
      session.hostUserId === userId &&
      (session.status === "waiting" || session.status === "playing")
    ) {
      await this.prisma.vibeGameSession.update({
        where: { id: sessionId },
        data: { hostUserId: remaining[0].userId },
      });
    }
    if (remaining.length > 0 && session.status === "playing") {
      await this.advanceIfReadyOrExpired(await this.getSession(sessionId));
    }
    return this.state(sessionId, userId);
  }

  async leaveRoom(clerkUserId: string, roomId: string) {
    const userId = await this.databaseUserId(clerkUserId);
    const memberships = await this.prisma.vibeGameParticipant.findMany({
      where: {
        userId,
        leftAt: null,
        session: { roomId, status: { in: ["waiting", "playing"] } },
      },
      select: { sessionId: true },
    });
    await this.prisma.vibeGameParticipant.updateMany({
      where: {
        userId,
        leftAt: null,
        session: { roomId, status: { in: ["waiting", "playing"] } },
      },
      data: { leftAt: new Date() },
    });
    for (const { sessionId } of memberships) {
      const session = await this.getSession(sessionId);
      const remaining = await this.prisma.vibeGameParticipant.findMany({
        where: { sessionId, leftAt: null },
        orderBy: { joinedAt: "asc" },
        select: { userId: true },
      });
      const hostDependent =
        session.gameType === "guess_my_vibe" ||
        session.gameType === "two_truths_and_a_lie";
      if (
        remaining.length === 0 ||
        (hostDependent && session.hostUserId === userId)
      ) {
        await this.prisma.vibeGameSession.updateMany({
          where: { id: sessionId, status: { in: ["waiting", "playing"] } },
          data: {
            status: "cancelled",
            activeRoomId: null,
            finishedAt: new Date(),
          },
        });
      } else if (session.hostUserId === userId) {
        await this.prisma.vibeGameSession.update({
          where: { id: sessionId },
          data: { hostUserId: remaining[0].userId },
        });
      }
      if (remaining.length > 0 && session.status === "playing") {
        await this.advanceIfReadyOrExpired(await this.getSession(sessionId));
      }
    }
    return memberships.map(({ sessionId }) => sessionId);
  }

  async roomId(sessionId: string) {
    return (await this.getSession(sessionId)).roomId;
  }

  async assertSessionInRoom(sessionId: string, roomId: string) {
    const session = await this.getSession(sessionId);
    if (session.roomId !== roomId)
      throw new NotFoundException("Game session not found.");
  }

  private async advanceIfReadyOrExpired(session: VibeGameSession) {
    if (session.status !== "playing") return;
    const questions = this.questionsFor(session);
    const [playerCount, answerCount] = await Promise.all([
      this.prisma.vibeGameParticipant.count({
        where: { sessionId: session.id, leftAt: null },
      }),
      this.prisma.vibeGameAnswer.count({
        where: {
          sessionId: session.id,
          questionIndex: session.questionIndex,
          participant: { leftAt: null },
          ...(session.gameType === "two_truths_and_a_lie"
            ? { userId: { not: session.hostUserId } }
            : {}),
        },
      }),
    ]);
    const requiredAnswers =
      session.gameType === "two_truths_and_a_lie"
        ? Math.max(0, playerCount - 1)
        : playerCount;
    const expired =
      session.questionDeadline != null &&
      session.questionDeadline.getTime() <= Date.now();
    if (!expired && (playerCount === 0 || answerCount < requiredAnswers))
      return;
    const nextIndex = session.questionIndex + 1;
    if (nextIndex >= questions.length) {
      await this.prisma.vibeGameSession.updateMany({
        where: {
          id: session.id,
          status: "playing",
          questionIndex: session.questionIndex,
        },
        data: {
          status: "completed",
          activeRoomId: null,
          finishedAt: new Date(),
          questionDeadline: null,
        },
      });
      return;
    }
    await this.prisma.vibeGameSession.updateMany({
      where: {
        id: session.id,
        status: "playing",
        questionIndex: session.questionIndex,
      },
      data: {
        questionIndex: nextIndex,
        questionDeadline: new Date(
          (expired ? session.questionDeadline!.getTime() : Date.now()) + 45_000,
        ),
      },
    });
    if (expired)
      await this.advanceIfReadyOrExpired(await this.getSession(session.id));
  }

  private async state(sessionId: string, viewerId: string) {
    const session = await this.prisma.vibeGameSession.findUnique({
      where: { id: sessionId },
      include: {
        participants: {
          include: participantInclude,
          orderBy: { joinedAt: "asc" },
        },
      },
    });
    if (!session) throw new NotFoundException("Game session not found.");
    const definition = games[session.gameType];
    const activeParticipants = session.participants.filter(
      (participant) => !participant.leftAt,
    );
    const currentAnswers = activeParticipants
      .filter(
        (p) =>
          session.gameType !== "two_truths_and_a_lie" ||
          p.userId !== session.hostUserId,
      )
      .flatMap((participant) =>
        participant.answers
          .filter((answer) => answer.questionIndex === session.questionIndex)
          .map((answer) => ({ ...answer, userId: participant.userId })),
      );
    const requiredPlayers =
      session.gameType === "two_truths_and_a_lie"
        ? activeParticipants.filter((p) => p.userId !== session.hostUserId)
        : activeParticipants;
    const allAnswered =
      requiredPlayers.length > 0 &&
      requiredPlayers.every((p) =>
        currentAnswers.some((answer) => answer.userId === p.userId),
      );
    return {
      id: session.id,
      roomId: session.roomId,
      gameType: session.gameType,
      title: definition.title,
      status: session.status,
      hostId: session.hostUserId,
      isHost: session.hostUserId === viewerId,
      isParticipant: activeParticipants.some(
        (participant) => participant.userId === viewerId,
      ),
      questionIndex: session.questionIndex,
      questionCount: this.questionsFor(session).length,
      question:
        session.status === "playing"
          ? (this.questionsFor(session)[session.questionIndex] ?? null)
          : null,
      secondsRemaining: session.questionDeadline
        ? Math.max(
            0,
            Math.ceil((session.questionDeadline.getTime() - Date.now()) / 1000),
          )
        : null,
      players: activeParticipants.map((p) => ({
        id: p.user.id,
        name:
          [p.user.firstName, p.user.lastName].filter(Boolean).join(" ") ||
          p.user.username ||
          "Member",
        avatar: p.user.profile?.photos[0]?.secureUrl ?? p.user.imageUrl ?? "",
        isHost: p.user.id === session.hostUserId,
        hasAnswered: currentAnswers.some(
          (answer) => answer.userId === p.user.id,
        ),
        choiceIndex:
          session.status === "completed"
            ? (p.answers.find((a) => a.questionIndex === session.questionIndex)
                ?.choiceIndex ?? null)
            : null,
      })),
      playerCount: session.participants.filter((p) => !p.leftAt).length,
      answeredCount: currentAnswers.length,
      allAnswered,
      myChoiceIndex:
        currentAnswers.find((answer) => answer.userId === viewerId)
          ?.choiceIndex ?? null,
      createdAt: session.createdAt.toISOString(),
      results:
        session.status === "completed"
          ? this.questionsFor(session).map((question, index) => ({
              questionIndex: index,
              prompt: question.prompt,
              options: question.options,
              correctChoiceIndex:
                session.gameType === "two_truths_and_a_lie"
                  ? ((session.setup as { lieIndex?: number } | null)
                      ?.lieIndex ?? null)
                  : null,
              votes: activeParticipants.flatMap((participant) => {
                const answer = participant.answers.find(
                  (item) => item.questionIndex === index,
                );
                return answer
                  ? [
                      {
                        userId: participant.userId,
                        name:
                          [
                            participant.user.firstName,
                            participant.user.lastName,
                          ]
                            .filter(Boolean)
                            .join(" ") ||
                          participant.user.username ||
                          "Member",
                        choiceIndex: answer.choiceIndex,
                      },
                    ]
                  : [];
              }),
            }))
          : [],
    };
  }

  private async getSession(id: string): Promise<VibeGameSession> {
    const session = await this.prisma.vibeGameSession.findUnique({
      where: { id },
    });
    if (!session) throw new NotFoundException("Game session not found.");
    if (
      session.status === "waiting" &&
      Date.now() - session.createdAt.getTime() > 600_000
    ) {
      await this.prisma.vibeGameSession.updateMany({
        where: { id, status: "waiting" },
        data: {
          status: "cancelled",
          activeRoomId: null,
          finishedAt: new Date(),
        },
      });
      return this.getSession(id);
    }
    return session;
  }

  private questionsFor(session: VibeGameSession): GameQuestion[] {
    if (session.gameType === "two_truths_and_a_lie") {
      const setup = session.setup as { statements?: unknown[] } | null;
      const statements =
        setup?.statements?.filter(
          (item): item is string => typeof item === "string",
        ) ?? [];
      if (statements.length === 3) {
        return [
          {
            prompt: "Which statement about the host is the lie?",
            options: statements,
          },
        ];
      }
    }
    return games[session.gameType]?.questions ?? [];
  }

  private async databaseUserId(clerkUserId: string) {
    const user = await this.prisma.user.findUnique({
      where: { clerkUserId },
      select: { id: true },
    });
    if (!user) throw new NotFoundException("User account is not ready yet.");
    return user.id;
  }

  private async assertRoomMember(userId: string, roomId: string) {
    const member = await this.prisma.vibeRoomMember.findUnique({
      where: { roomId_userId: { roomId, userId } },
      select: { leftAt: true },
    });
    if (!member || member.leftAt)
      throw new ForbiddenException(
        "Join this Vibe room before playing its games.",
      );
  }
}
