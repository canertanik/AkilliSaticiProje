using System.ComponentModel.DataAnnotations;

namespace AkilliSatici.Api.Dtos;

public record OrderItemCreateDto(
    int? ProductId,
    [Required, MaxLength(200)] string ProductTitle,
    decimal UnitPrice,
    [Range(1, 999)] int Quantity
);

public record OrderCreateDto(
    [Required, MaxLength(120)] string CustomerName,
    [Required, EmailAddress, MaxLength(200)] string CustomerEmail,
    [Required, MaxLength(20)] string CustomerPhone,
    [Required, MaxLength(80)] string DeliveryCity,
    [Required, MaxLength(80)] string DeliveryDistrict,
    [Required, MaxLength(160)] string DeliveryNeighborhood,
    [Required, MaxLength(400)] string DeliveryAddressLine,
    [Required, MaxLength(16)] string PostalCode,
    [Required, MaxLength(40)] string AddressTitle,
    [MaxLength(500)] string? OrderNote,
    [Required, MaxLength(40)] string PaymentMethod,
    List<OrderItemCreateDto> Items
);
