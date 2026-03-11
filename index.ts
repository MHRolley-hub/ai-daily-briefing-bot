
{
  "bindings": [
    {
      "authLevel": "function",
      "type": "httpTrigger",
      "direction": "in",
      "name": "req",
      "methods": ["POST", "GET"],
      "route": "api/messages"
    },
    {
      "type": "http",
      "direction": "out",
      "name": "res"
    }
  ]
}
