defmodule SummerChallengeWeb.PageController do
  use SummerChallengeWeb, :controller

  def home(conn, _params) do
    html = """
    <!DOCTYPE html>
    <html lang="en">
      <head>
        <meta charset="utf-8"/>
        <meta name="viewport" content="width=device-width, initial-scale=1"/>
        <title>Summer Challenge</title>
        <style>
          body {
            font-family: system-ui, -apple-system, sans-serif;
            margin: 0;
            padding: 2rem;
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            color: white;
            min-height: 100vh;
            display: flex;
            align-items: center;
            justify-content: center;
          }
          .container {
            text-align: center;
            max-width: 600px;
          }
          h1 {
            font-size: 3rem;
            margin-bottom: 1rem;
            text-shadow: 2px 2px 4px rgba(0,0,0,0.3);
          }
          p {
            font-size: 1.2rem;
            opacity: 0.9;
          }
        </style>
      </head>
      <body>
        <div class="container">
          <h1>Welcome to Summer Challenge</h1>
          <p>Your Phoenix application with LiveView is running successfully!</p>
        </div>
      </body>
    </html>
    """
    conn
    |> put_resp_content_type("text/html")
    |> send_resp(200, html)
  end
end
