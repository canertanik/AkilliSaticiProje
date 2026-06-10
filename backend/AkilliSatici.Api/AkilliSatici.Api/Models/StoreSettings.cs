using System.ComponentModel.DataAnnotations;

namespace AkilliSatici.Api.Models;

public class StoreSettings
{
    [Key]
    public int Id { get; set; }
    
    // Storing as JSON string to keep it simple in SQL Server without creating separate tables
    public string PopularCategoriesJson { get; set; } = "[]";
    public string PopularBrandsJson { get; set; } = "[]";
}
