using AkilliSatici.Api.Data;
using AkilliSatici.Api.Models;
using AkilliSatici.Api.Services;
using AkilliSatici.Api.Dtos;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using System.Security.Cryptography;
using System.Security.Claims;
using System.Text;
using Microsoft.Extensions.Logging;
using Microsoft.AspNetCore.Authorization;

namespace AkilliSatici.Api.Controllers;

[ApiController]
[Route("api/[controller]")]
public class AuthController : ControllerBase
{
    private readonly AppDbContext _db;
    private readonly JwtService _jwt;
    private readonly EmailService _emailService;
    private readonly ILogger<AuthController> _logger;

    public AuthController(AppDbContext db, JwtService jwt, EmailService emailService, ILogger<AuthController> logger)
    {
        _db = db;
        _jwt = jwt;
        _emailService = emailService;
        _logger = logger;
    }


    [HttpPost("register")]
    public async Task<IActionResult> Register(RegisterDto dto)
    {
        var email = dto.Email.Trim().ToLower();

        if (await _db.Users.AnyAsync(u => u.Email == email))
            return BadRequest(new { message = "Bu e-posta zaten kayıtlı." });

        CreatePasswordHash(dto.Password, out var hash, out var salt);

        var user = new AppUser
        {
            FullName = dto.FullName.Trim(),
            StoreName = dto.StoreName.Trim(),
            Email = email,
            PasswordHash = hash,
            PasswordSalt = salt,
            IsAdmin = false
        };

        _db.Users.Add(user);
        await _db.SaveChangesAsync();

        return Ok(new { message = "Kayıt başarılı" });
    }

    [HttpPost("login")]
    public async Task<IActionResult> Login(LoginDto dto)
    {
        var email = dto.Email.Trim().ToLower();
        var user = await _db.Users.FirstOrDefaultAsync(u => u.Email == email);

        if (user == null)
            return Unauthorized(new { message = "Hatalı giriş" });

        var ok = VerifyPasswordHash(dto.Password, user.PasswordHash, user.PasswordSalt);
        if (!ok)
            return Unauthorized(new { message = "Hatalı giriş" });

        var token = _jwt.CreateToken(user);
        return Ok(new
        {
            token,
            user = new
            {
                user.Id,
                user.FullName,
                user.Email,
                user.StoreName,
                user.IsAdmin,
                user.PawPoints
            }
        });
    }

    [Authorize]
    [HttpGet("me")]
    public async Task<IActionResult> Me()
    {
        var sub = User.FindFirstValue(ClaimTypes.NameIdentifier)
                  ?? User.FindFirstValue(System.IdentityModel.Tokens.Jwt.JwtRegisteredClaimNames.Sub);

        if (string.IsNullOrWhiteSpace(sub) || !int.TryParse(sub, out var userId))
            return Unauthorized();

        var user = await _db.Users.AsNoTracking().FirstOrDefaultAsync(x => x.Id == userId);
        if (user is null) return Unauthorized();

        return Ok(new
        {
            user.Id,
            user.FullName,
            user.Email,
            user.StoreName,
            user.IsAdmin,
            user.PawPoints
        });
    }

    [HttpPost("forgot-password")]
    public async Task<IActionResult> ForgotPassword(ForgotPasswordDto dto)
    {
        var email = dto.Email.Trim().ToLower();
        var user = await _db.Users.FirstOrDefaultAsync(u => u.Email == email);
        if (user == null)
            return Ok(new { message = "Eğer e-posta kayıtlıysa, sıfırlama kodu gönderildi." });

        var code = new Random().Next(100000, 999999).ToString();

        user.ResetCode = code;
        user.ResetCodeExpires = DateTime.UtcNow.AddMinutes(15);
        await _db.SaveChangesAsync();

        try
        {
            await _emailService.SendResetCodeAsync(user.Email, code);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Reset kodu gönderilemedi. Email: {Email}", user.Email);
            return StatusCode(500, new { message = "Kod gönderilirken bir hata oluştu. Lütfen daha sonra tekrar deneyin." });
        }


        return Ok(new { message = "Eğer e-posta kayıtlıysa, sıfırlama kodu gönderildi." });
    }

    [HttpPost("reset-password")]
    public async Task<IActionResult> ResetPassword(ResetPasswordDto dto)
    {
        var email = dto.Email.Trim().ToLower();
        var user = await _db.Users.FirstOrDefaultAsync(u => u.Email == email);
        if (user == null)
            return BadRequest(new { message = "Geçersiz kod veya e-posta." });

        if (user.ResetCode != dto.Code || user.ResetCodeExpires < DateTime.UtcNow)
            return BadRequest(new { message = "Geçersiz kod veya kodun süresi dolmuş." });

        CreatePasswordHash(dto.NewPassword, out var hash, out var salt);
        user.PasswordHash = hash;
        user.PasswordSalt = salt;
        user.ResetCode = null;
        user.ResetCodeExpires = null;

        await _db.SaveChangesAsync();

        return Ok(new { message = "Şifre başarıyla sıfırlandı." });
    }

    // Şifre hash işlemleri
    private void CreatePasswordHash(string password, out byte[] hash, out byte[] salt)
    {
        using var hmac = new HMACSHA512();
        salt = hmac.Key;
        hash = hmac.ComputeHash(Encoding.UTF8.GetBytes(password));
    }

    private bool VerifyPasswordHash(string password, byte[] storedHash, byte[] storedSalt)
    {
        using var hmac = new HMACSHA512(storedSalt);
        var computed = hmac.ComputeHash(Encoding.UTF8.GetBytes(password));
        return computed.SequenceEqual(storedHash);
    }
}
