
import { AzureFunction, Context, HttpRequest } from "@azure/functions";
import { CloudAdapter, ConfigurationBotFrameworkAuthentication, ConfigurationServiceClientCredentialFactory, TurnContext, TeamsActivityHandler } from "botbuilder";
import { TableClient } from "@azure/data-tables";

class RefCaptureBot extends TeamsActivityHandler {
  constructor(private table: TableClient) {
    super();
    this.onConversationUpdate(async (context, next) => {
      await this.tryStoreRef(context);
      await next();
    });
    this.onMessage(async (context, next) => {
      await this.tryStoreRef(context);
      await context.sendActivity("Thanks! I’ll post the AI Daily Briefing here on schedule.");
      await next();
    });
  }
  private async tryStoreRef(context: TurnContext) {
    const conv = context.activity.conversation;
    const entity = {
      partitionKey: "GroupChat",
      rowKey: "Primary",
      conversationId: conv.id,
      serviceUrl: context.activity.serviceUrl,
      updated: new Date().toISOString()
    } as any;
    await this.table.createTable({ onResponse: () => {} } as any).catch(() => {});
    await this.table.upsertEntity(entity, "Merge");
  }
}

const httpTrigger: AzureFunction = async function (context: Context, req: HttpRequest): Promise<void> {
  const credentialsFactory = new ConfigurationServiceClientCredentialFactory({
    MicrosoftAppId: process.env.BOT_APP_ID,
    MicrosoftAppPassword: process.env.BOT_APP_PASSWORD
  });
  const botFrameworkAuthentication = new ConfigurationBotFrameworkAuthentication({}, credentialsFactory);
  const adapter = new CloudAdapter(botFrameworkAuthentication);

  const tableConnStr = process.env.TABLE_CONN_STR!;
  const tableName = process.env.TABLE_NAME || "ConversationRefs";
  const table = TableClient.fromConnectionString(tableConnStr, tableName);
  const bot = new RefCaptureBot(table);

  await adapter.process(req as any, context.res as any, async (turnContext) => {
    await bot.run(turnContext);
  });

  if (!context.res) context.res = { status: 200, body: "OK" } as any;
};

export default httpTrigger;
