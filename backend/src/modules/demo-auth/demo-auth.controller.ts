import { Body, Controller, Get, Post } from "@nestjs/common";
import { DemoAuthService } from "./demo-auth.service";

@Controller("auth/demo")
export class DemoAuthController {
  constructor(private readonly demoAuth: DemoAuthService) {}

  @Get("users")
  listUsers() {
    return this.demoAuth.listUsers();
  }

  @Post("login")
  login(@Body() body: { username?: unknown }) {
    return this.demoAuth.login(body?.username);
  }
}
