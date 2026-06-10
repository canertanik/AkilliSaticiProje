namespace AkilliSatici.Api.Dtos;

public record PetProfileCreateDto(
    string Name,
    string Species,
    string? Breed,
    int AgeYears,
    int AgeMonths,
    double? WeightKg,
    bool IsNeutered
);
