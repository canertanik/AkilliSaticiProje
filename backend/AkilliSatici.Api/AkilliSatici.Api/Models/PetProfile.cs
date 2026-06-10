using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace AkilliSatici.Api.Models;

public class PetProfile
{
    public int Id { get; set; }

    [ForeignKey(nameof(User))]
    public int UserId { get; set; }
    public AppUser? User { get; set; }

    [Required, MaxLength(100)]
    public string Name { get; set; } = "";

    [Required, MaxLength(50)]
    public string Species { get; set; } = ""; // e.g. "Kedi", "Köpek"

    [MaxLength(100)]
    public string? Breed { get; set; } // e.g. "Golden Retriever"

    public int AgeYears { get; set; }
    public int AgeMonths { get; set; }

    public double? WeightKg { get; set; }

    public bool IsNeutered { get; set; }

    public DateTime CreatedAtUtc { get; set; } = DateTime.UtcNow;
}
