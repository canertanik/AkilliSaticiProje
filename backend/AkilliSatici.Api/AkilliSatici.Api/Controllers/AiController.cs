using System;
using System.IO;
using System.Linq;
using System.Net.Http;
using System.Text;
using System.Threading.Tasks;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Http;
using Microsoft.Extensions.Logging;
using Microsoft.AspNetCore.Authorization;

namespace AkilliSatici.Api.Controllers;

[ApiController]
[Route("api/ai")]
[AllowAnonymous]
public class AiController : ControllerBase
{
    private readonly IHttpClientFactory _httpFactory;
    private readonly ILogger<AiController> _logger;

    public AiController(IHttpClientFactory httpFactory, ILogger<AiController> logger)
    {
        _httpFactory = httpFactory;
        _logger = logger;
    }

    [HttpPost("suggest")]
    [RequestSizeLimit(5 * 1024 * 1024)] // 5 MB
    public async Task<IActionResult> Suggest()
    {
        try
        {
            Request.EnableBuffering();

            var client = _httpFactory.CreateClient("AiProxy");

            if (Request.Body.CanSeek)
                Request.Body.Position = 0;

            // Read entire request body into memory to avoid partial-read issues when proxying
            byte[] bodyBytes;
            using (var ms = new MemoryStream())
            {
                await Request.Body.CopyToAsync(ms);
                bodyBytes = ms.ToArray();
            }

            var byteContent = new ByteArrayContent(bodyBytes);
            if (!string.IsNullOrEmpty(Request.ContentType))
                byteContent.Headers.TryAddWithoutValidation("Content-Type", Request.ContentType);

            var proxied = new HttpRequestMessage(HttpMethod.Post, "ai/suggest")
            {
                Content = byteContent
            };

            // Copy headers except Host
            foreach (var h in Request.Headers)
            {
                if (string.Equals(h.Key, "Host", StringComparison.OrdinalIgnoreCase))
                    continue;

                if (!proxied.Headers.TryAddWithoutValidation(h.Key, h.Value.ToArray()))
                    proxied.Content?.Headers.TryAddWithoutValidation(h.Key, h.Value.ToArray());
            }

            _logger.LogInformation("Proxying /api/ai/suggest from {RemoteIp} content-length={Len}", HttpContext.Connection.RemoteIpAddress, Request.ContentLength);

            var resp = await client.SendAsync(proxied, HttpCompletionOption.ResponseHeadersRead);

            var respStream = await resp.Content.ReadAsStreamAsync();

            // copy response headers
            foreach (var header in resp.Content.Headers)
            {
                Response.Headers[header.Key] = string.Join(",", header.Value);
            }

            Response.StatusCode = (int)resp.StatusCode;
            var contentType = resp.Content.Headers.ContentType?.ToString() ?? "application/json";
            return new FileStreamResult(respStream, contentType);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error proxying AI suggest");
            return StatusCode(500, new { message = "Proxy error", detail = ex.Message });
        }
    }

    [HttpPost("price-scrape")]
    public async Task<IActionResult> PriceScrape()
    {
        try
        {
            // Read body into memory (payloads are expected to be small)
            Request.EnableBuffering();
            if (Request.Body.CanSeek)
                Request.Body.Position = 0;

            byte[] bodyBytes;
            using (var ms = new MemoryStream())
            {
                await Request.Body.CopyToAsync(ms);
                bodyBytes = ms.ToArray();
            }

            var client = _httpFactory.CreateClient("AiProxy");

            var byteContent = new ByteArrayContent(bodyBytes);
            if (!string.IsNullOrEmpty(Request.ContentType))
                byteContent.Headers.TryAddWithoutValidation("Content-Type", Request.ContentType);

            var proxied = new HttpRequestMessage(HttpMethod.Post, "price/scrape")
            {
                Content = byteContent
            };

            // Copy headers except Host and Content-Length (will be set by HttpClient)
            foreach (var h in Request.Headers)
            {
                if (string.Equals(h.Key, "Host", StringComparison.OrdinalIgnoreCase))
                    continue;
                if (string.Equals(h.Key, "Content-Length", StringComparison.OrdinalIgnoreCase))
                    continue;

                if (!proxied.Headers.TryAddWithoutValidation(h.Key, h.Value.ToArray()))
                    proxied.Content?.Headers.TryAddWithoutValidation(h.Key, h.Value.ToArray());
            }

            _logger.LogInformation("Proxying /api/ai/price-scrape from {RemoteIp}", HttpContext.Connection.RemoteIpAddress);

            var resp = await client.SendAsync(proxied, HttpCompletionOption.ResponseHeadersRead);

            var respBody = await resp.Content.ReadAsStringAsync();

            // copy response headers
            foreach (var header in resp.Content.Headers)
            {
                Response.Headers[header.Key] = string.Join(",", header.Value);
            }

            return new ContentResult
            {
                Content = respBody,
                StatusCode = (int)resp.StatusCode,
                ContentType = resp.Content.Headers.ContentType?.ToString() ?? "application/json"
            };
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error proxying AI price-scrape");
            return StatusCode(500, new { message = "Proxy error", detail = ex.Message });
        }
    }

    [HttpPost("chat")]
    [AllowAnonymous]
    public async Task<IActionResult> Chat()
    {
        try
        {
            Request.EnableBuffering();
            if (Request.Body.CanSeek)
                Request.Body.Position = 0;

            byte[] bodyBytes;
            using (var ms = new MemoryStream())
            {
                await Request.Body.CopyToAsync(ms);
                bodyBytes = ms.ToArray();
            }

            var client = _httpFactory.CreateClient("AiProxy");

            var byteContent = new ByteArrayContent(bodyBytes);
            if (!string.IsNullOrEmpty(Request.ContentType))
                byteContent.Headers.TryAddWithoutValidation("Content-Type", Request.ContentType);

            var proxied = new HttpRequestMessage(HttpMethod.Post, "ai/chat")
            {
                Content = byteContent
            };

            foreach (var h in Request.Headers)
            {
                if (string.Equals(h.Key, "Host", StringComparison.OrdinalIgnoreCase))
                    continue;
                if (string.Equals(h.Key, "Content-Length", StringComparison.OrdinalIgnoreCase))
                    continue;

                if (!proxied.Headers.TryAddWithoutValidation(h.Key, h.Value.ToArray()))
                    proxied.Content?.Headers.TryAddWithoutValidation(h.Key, h.Value.ToArray());
            }

            _logger.LogInformation("Proxying /api/ai/chat from {RemoteIp}", HttpContext.Connection.RemoteIpAddress);

            var resp = await client.SendAsync(proxied, HttpCompletionOption.ResponseHeadersRead);
            var respBody = await resp.Content.ReadAsStringAsync();

            foreach (var header in resp.Content.Headers)
            {
                Response.Headers[header.Key] = string.Join(",", header.Value);
            }

            return new ContentResult
            {
                Content = respBody,
                StatusCode = (int)resp.StatusCode,
                ContentType = resp.Content.Headers.ContentType?.ToString() ?? "application/json"
            };
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error proxying AI chat");
            return StatusCode(500, new { message = "Proxy error", detail = ex.Message });
        }
    }
}
