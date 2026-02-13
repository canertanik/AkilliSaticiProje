using System.Net;
using System.Net.Mail;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.Logging;

namespace AkilliSatici.Api.Services;

public class EmailService
{
    private readonly IConfiguration _config;
    private readonly ILogger<EmailService> _logger;

    public EmailService(IConfiguration config, ILogger<EmailService> logger)
    {
        _config = config;
        _logger = logger;
    }

    public async Task SendResetCodeAsync(string toEmail, string code)
    {
        var smtpServer = _config["EmailSettings:SmtpServer"];
        var smtpPortStr = _config["EmailSettings:SmtpPort"];
        var smtpUser = _config["EmailSettings:SmtpUser"];
        var smtpPass = _config["EmailSettings:SmtpPass"];

        if (string.IsNullOrWhiteSpace(smtpServer))
            throw new InvalidOperationException("SMTP server is not configured.");
        if (!int.TryParse(smtpPortStr, out var smtpPort))
            throw new InvalidOperationException("SMTP port is not configured properly.");
        if (string.IsNullOrWhiteSpace(smtpUser))
            throw new InvalidOperationException("SMTP user is not configured.");
        if (string.IsNullOrWhiteSpace(smtpPass))
            throw new InvalidOperationException("SMTP password is not configured.");
        if (string.IsNullOrWhiteSpace(toEmail))
            throw new ArgumentException("Recipient email is required.", nameof(toEmail));

        try
        {
            _logger.LogInformation("Sending reset code to {ToEmail}", toEmail);

            using var client = new SmtpClient(smtpServer, smtpPort)
            {
                Credentials = new NetworkCredential(smtpUser, smtpPass),
                EnableSsl = true
            };

            using var mail = new MailMessage(smtpUser, toEmail)
            {
                Subject = "Password Reset Code",
                Body = $"Your reset code: {code}",
                IsBodyHtml = false
            };

            await client.SendMailAsync(mail);

            _logger.LogInformation("Reset code sent to {ToEmail}", toEmail);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "SMTP send error. To: {ToEmail}", toEmail);
            throw;
        }
    }
}
