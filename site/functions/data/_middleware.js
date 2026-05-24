export async function onRequest(context) {
  const { request, env } = context;

  const url = new URL(request.url);

  const key = url.pathname.replace(/^\/data\//, "");

  const object = await env.MY_BUCKET.get(key);

  if (!object) {
    return new Response("Not found", { status: 404 });
  }

  const headers = new Headers();

  object.writeHttpMetadata(headers);

  const quoteETag = `"${object.etag}"`
  headers.set(
    "Cache-Control",
    object.httpMetadata?.cacheControl || "public, max-age=60"
  );
  headers.set("ETag", quoteETag);
  headers.set("Last-Modified", object.uploaded.toUTCString());

  const ifNoneMatch = request.headers.get("If-None-Match") || "";
  if (ifNoneMatch.includes(quoteETag)) {
    return new Response(null, { status: 304, headers });
  }

  const ifModifiedSince = request.headers.get("If-Modified-Since");
  if (ifModifiedSince) {
    const since = new Date(ifModifiedSince);
    if (object.uploaded <= since) {
      return new Response(null, { status: 304, headers });
    }
  }

  if (key.endsWith(".json")) {
    headers.set("Content-Type", "application/json");
  }

  if (request.method === "HEAD") {
    return new Response(null, { headers });
  }
  return new Response(object.body, { headers });
}
