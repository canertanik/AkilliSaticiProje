using System.ComponentModel.DataAnnotations;

namespace AkilliSatici.Api.Dtos;

public record ForgotPasswordDto(
	[Required, EmailAddress] string Email
);