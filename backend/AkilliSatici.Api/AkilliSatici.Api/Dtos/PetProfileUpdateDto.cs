namespace AkilliSatici.Api.Dtos;

public record PetProfileUpdateDto(
    string Name,
    string Species,
    string? Breed,
    int AgeYears,
    int AgeMonths,
    double? WeightKg,
    bool IsNeutered
);
