using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace AkilliSatici.Api.Models;

public enum ProductStatus
{
    Draft ,
    Published
}

public class Product
{
    public int Id { get; set; }

    [ForeignKey(nameof(User))]
    public int UserId { get; set; }
    public AppUser? User { get; set; }

    [Required, MaxLength(200)]
    public string Title { get; set; } = "";

    [MaxLength(4000)]
    public string? Description { get; set; }

    public decimal? MinPrice { get; set; }
    public decimal? MaxPrice { get; set; }

    [MaxLength(120)]
    public string? Category { get; set; }

    [MaxLength(500)]
    public string? ImageUrl { get; set; }

    public bool IsAiGenerated { get; set; }

    public ProductStatus Status { get; set; } = ProductStatus.Draft;

    public DateTime CreatedAtUtc { get; set; } = DateTime.UtcNow;
    public DateTime? UpdatedAtUtc { get; set; }
}
