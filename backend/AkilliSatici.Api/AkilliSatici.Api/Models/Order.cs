using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace AkilliSatici.Api.Models;

public enum OrderStatus
{
    Pending,
    Preparing,
    Shipped,
    Completed,
    Cancelled
}

public class Order
{
    public int Id { get; set; }

    [ForeignKey(nameof(User))]
    public int? UserId { get; set; }
    public AppUser? User { get; set; }

    [Required, MaxLength(120)]
    public string CustomerName { get; set; } = "";

    [Required, MaxLength(200)]
    public string CustomerEmail { get; set; } = "";

    [Required, MaxLength(20)]
    public string CustomerPhone { get; set; } = "";

    [Required, MaxLength(80)]
    public string DeliveryCity { get; set; } = "";

    [Required, MaxLength(80)]
    public string DeliveryDistrict { get; set; } = "";

    [Required, MaxLength(160)]
    public string DeliveryNeighborhood { get; set; } = "";

    [Required, MaxLength(400)]
    public string DeliveryAddressLine { get; set; } = "";

    [Required, MaxLength(16)]
    public string PostalCode { get; set; } = "";

    [Required, MaxLength(40)]
    public string AddressTitle { get; set; } = "";

    [MaxLength(500)]
    public string? OrderNote { get; set; }

    [Required, MaxLength(40)]
    public string PaymentMethod { get; set; } = "";

    public decimal TotalAmount { get; set; }

    public OrderStatus Status { get; set; } = OrderStatus.Pending;

    public DateTime CreatedAtUtc { get; set; } = DateTime.UtcNow;

    public List<OrderItem> Items { get; set; } = new();
}

public class OrderItem
{
    public int Id { get; set; }

    [ForeignKey(nameof(Order))]
    public int OrderId { get; set; }
    public Order? Order { get; set; }

    public int? ProductId { get; set; }

    [Required, MaxLength(200)]
    public string ProductTitle { get; set; } = "";

    public decimal UnitPrice { get; set; }

    public int Quantity { get; set; }
}
