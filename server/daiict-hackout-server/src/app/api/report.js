

export async function POST(request) {

  const { userId, reportData } = await request.json();

  if (!userId || !reportData) {
    return new Response("Invalid input", { status: 400 });
  }

  return new Response("Report submitted successfully", { status: 200 });
}
