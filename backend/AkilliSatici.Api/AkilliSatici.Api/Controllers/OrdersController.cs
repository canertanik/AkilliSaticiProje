using AkilliSatici.Api.Data;
using AkilliSatici.Api.Dtos;
using AkilliSatici.Api.Models;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using System.IdentityModel.Tokens.Jwt;
using System.Security.Claims;

namespace AkilliSatici.Api.Controllers;

[ApiController]
[Route("api/[controller]")]
[Authorize]
public class OrdersController : ControllerBase
{
    private readonly AppDbContext _db;

    public OrdersController(AppDbContext db)
    {
        _db = db;
    }

    private int? TryGetUserId()
    {
        var sub = User.FindFirstValue(ClaimTypes.NameIdentifier)
                  ?? User.FindFirstValue(JwtRegisteredClaimNames.Sub);

        if (string.IsNullOrWhiteSpace(sub) || !int.TryParse(sub, out var userId))
            return null;

        return userId;
    }

    [HttpGet]
    [Authorize(Roles = "Admin")]
    public async Task<IActionResult> GetAll()
    {
        var list = await _db.Orders
            .AsNoTracking()
            .OrderByDescending(o => o.CreatedAtUtc)
            .Select(o => new AdminOrderListItemDto
            {
                Id = o.Id,
                CustomerName = o.CustomerName,
                CustomerEmail = o.CustomerEmail,
                CustomerPhone = o.CustomerPhone,
                DeliveryCity = o.DeliveryCity,
                DeliveryDistrict = o.DeliveryDistrict,
                DeliveryNeighborhood = o.DeliveryNeighborhood,
                DeliveryAddressLine = o.DeliveryAddressLine,
                PostalCode = o.PostalCode,
                AddressTitle = o.AddressTitle,
                OrderNote = o.OrderNote,
                PaymentMethod = o.PaymentMethod,
                TotalAmount = o.TotalAmount,
                Status = o.Status.ToString(),
                CreatedAtUtc = o.CreatedAtUtc,
                Items = o.Items.Select(i => new AdminOrderListItemDetailDto
                {
                    Id = i.Id,
                    ProductId = i.ProductId,
                    ProductTitle = i.ProductTitle,
                    UnitPrice = i.UnitPrice,
                    Quantity = i.Quantity
                }).ToList()
            })
            .ToListAsync();

        return Ok(list);
    }

    [HttpPost]
    [AllowAnonymous]
    public async Task<IActionResult> Create(OrderCreateDto dto)
    {
        if (dto.Items is null || dto.Items.Count == 0)
            return BadRequest(new { message = "Sipariş için en az bir ürün gerekli." });

        var order = new Order
        {
            UserId = User.Identity?.IsAuthenticated == true ? TryGetUserId() : null,
            CustomerName = dto.CustomerName.Trim(),
            CustomerEmail = dto.CustomerEmail.Trim().ToLower(),
            CustomerPhone = dto.CustomerPhone.Trim(),
            DeliveryCity = dto.DeliveryCity.Trim(),
            DeliveryDistrict = dto.DeliveryDistrict.Trim(),
            DeliveryNeighborhood = dto.DeliveryNeighborhood.Trim(),
            DeliveryAddressLine = dto.DeliveryAddressLine.Trim(),
            PostalCode = dto.PostalCode.Trim(),
            AddressTitle = dto.AddressTitle.Trim(),
            OrderNote = string.IsNullOrWhiteSpace(dto.OrderNote)
                ? null
                : dto.OrderNote.Trim(),
            PaymentMethod = dto.PaymentMethod.Trim(),
            Items = dto.Items.Select(i => new OrderItem
            {
                ProductId = i.ProductId,
                ProductTitle = i.ProductTitle.Trim(),
                UnitPrice = i.UnitPrice,
                Quantity = i.Quantity
            }).ToList()
        };

        order.TotalAmount = order.Items.Sum(i => i.UnitPrice * i.Quantity);

        _db.Orders.Add(order);
        await _db.SaveChangesAsync();

        var response = new OrderCreateResponseDto
        {
            Id = order.Id,
            CustomerName = order.CustomerName,
            CustomerEmail = order.CustomerEmail,
            CustomerPhone = order.CustomerPhone,
            DeliveryCity = order.DeliveryCity,
            DeliveryDistrict = order.DeliveryDistrict,
            DeliveryNeighborhood = order.DeliveryNeighborhood,
            DeliveryAddressLine = order.DeliveryAddressLine,
            PostalCode = order.PostalCode,
            AddressTitle = order.AddressTitle,
            OrderNote = order.OrderNote,
            PaymentMethod = order.PaymentMethod,
            TotalAmount = order.TotalAmount,
            Status = order.Status,
            CreatedAtUtc = order.CreatedAtUtc,
            Items = order.Items.Select(i => new OrderCreateResponseItemDto
            {
                Id = i.Id,
                ProductId = i.ProductId,
                ProductTitle = i.ProductTitle,
                UnitPrice = i.UnitPrice,
                Quantity = i.Quantity
            }).ToList()
        };

        return Ok(response);
    }

    [HttpPut("{id:int}/status")]
    [Authorize(Roles = "Admin")]
    public async Task<IActionResult> UpdateStatus(int id, [FromQuery] OrderStatus status)
    {
        var order = await _db.Orders.FirstOrDefaultAsync(o => o.Id == id);
        if (order is null) return NotFound();

        order.Status = status;
        await _db.SaveChangesAsync();

        return Ok(order);
    }

    [HttpDelete("{id:int}")]
    [Authorize(Roles = "Admin")]
    public async Task<IActionResult> DeleteOrder(int id)
    {
        var order = await _db.Orders
            .Include(o => o.Items)
            .FirstOrDefaultAsync(o => o.Id == id);

        if (order is null) return NotFound(new { message = "Sipariş bulunamadı." });

        // Sadece tamamlanan veya iptal edilen siparişler silinebilir
        if (order.Status != OrderStatus.Completed && order.Status != OrderStatus.Cancelled)
            return BadRequest(new { message = "Yalnızca tamamlanan veya iptal edilen siparişler silinebilir." });

        _db.Orders.Remove(order);
        await _db.SaveChangesAsync();

        return Ok(new { message = "Sipariş silindi." });
    }

    [HttpGet("admin/dashboard")]
    [Authorize(Roles = "Admin")]
    public async Task<IActionResult> GetAdminDashboard()
    {
        var totalProducts = await _db.Products.CountAsync();

        var orders = await _db.Orders
            .AsNoTracking()
            .Include(o => o.Items)
            .OrderByDescending(o => o.CreatedAtUtc)
            .ToListAsync();

        var totalRevenue = orders.Sum(o => o.TotalAmount);
        var totalSalesCount = orders.Sum(o => o.Items.Sum(i => i.Quantity));

        var statusDistribution = Enum.GetValues<OrderStatus>()
            .Select(status => new DashboardStatusItemDto
            {
                Status = status.ToString(),
                Count = orders.Count(o => o.Status == status)
            })
            .ToList();

        var recentSales = orders
            .SelectMany(o => o.Items.Select(i => new DashboardRecentSaleDto
            {
                OrderId = o.Id,
                ProductId = i.ProductId,
                ProductTitle = i.ProductTitle,
                Quantity = i.Quantity,
                UnitPrice = i.UnitPrice,
                LineTotal = i.UnitPrice * i.Quantity,
                SoldAtUtc = o.CreatedAtUtc,
                CustomerName = o.CustomerName,
                Status = o.Status.ToString()
            }))
            .OrderByDescending(x => x.SoldAtUtc)
            .Take(20)
            .ToList();

        var dto = new DashboardMetricsDto
        {
            TotalProducts = totalProducts,
            TotalSalesCount = totalSalesCount,
            TotalRevenue = totalRevenue,
            StatusDistribution = statusDistribution,
            RecentSales = recentSales
        };

        return Ok(dto);
    }

    [HttpGet("admin/sales")]
    [Authorize(Roles = "Admin")]
    public async Task<IActionResult> GetSalesList([FromQuery] int page = 1, [FromQuery] int pageSize = 20)
    {
        if (page < 1) page = 1;
        if (pageSize < 1 || pageSize > 100) pageSize = 20;

        var total = await _db.Orders.CountAsync();

        var orders = await _db.Orders
            .AsNoTracking()
            .Include(o => o.Items)
            .OrderByDescending(o => o.CreatedAtUtc)
            .Skip((page - 1) * pageSize)
            .Take(pageSize)
            .ToListAsync();

        var salesList = orders.Select(o => new SalesListItemDto
        {
            OrderId = o.Id,
            CustomerName = o.CustomerName,
            CustomerEmail = o.CustomerEmail,
            ItemsCount = o.Items.Count,
            TotalQuantity = o.Items.Sum(i => i.Quantity),
            TotalAmount = o.TotalAmount,
            CreatedAtUtc = o.CreatedAtUtc,
            Status = o.Status.ToString(),
            Items = o.Items.Select(i => new SalesItemDetailDto
            {
                ProductTitle = i.ProductTitle,
                Quantity = i.Quantity,
                UnitPrice = i.UnitPrice,
                LineTotal = i.UnitPrice * i.Quantity
            }).ToList()
        }).ToList();

        var response = new SalesListResponseDto
        {
            TotalCount = total,
            Page = page,
            PageSize = pageSize,
            TotalPages = (int)Math.Ceiling(total / (double)pageSize),
            Items = salesList
        };

        return Ok(response);
    }
}

public class SalesListResponseDto
{
    public int TotalCount { get; set; }
    public int Page { get; set; }
    public int PageSize { get; set; }
    public int TotalPages { get; set; }
    public List<SalesListItemDto> Items { get; set; } = new();
}

public class AdminOrderListItemDto
{
    public int Id { get; set; }
    public string CustomerName { get; set; } = string.Empty;
    public string CustomerEmail { get; set; } = string.Empty;
    public string CustomerPhone { get; set; } = string.Empty;
    public string DeliveryCity { get; set; } = string.Empty;
    public string DeliveryDistrict { get; set; } = string.Empty;
    public string DeliveryNeighborhood { get; set; } = string.Empty;
    public string DeliveryAddressLine { get; set; } = string.Empty;
    public string PostalCode { get; set; } = string.Empty;
    public string AddressTitle { get; set; } = string.Empty;
    public string? OrderNote { get; set; }
    public string PaymentMethod { get; set; } = string.Empty;
    public decimal TotalAmount { get; set; }
    public string Status { get; set; } = string.Empty;
    public DateTime CreatedAtUtc { get; set; }
    public List<AdminOrderListItemDetailDto> Items { get; set; } = new();
}

public class AdminOrderListItemDetailDto
{
    public int Id { get; set; }
    public int? ProductId { get; set; }
    public string ProductTitle { get; set; } = string.Empty;
    public decimal UnitPrice { get; set; }
    public int Quantity { get; set; }
}

public class OrderCreateResponseDto
{
    public int Id { get; set; }
    public string CustomerName { get; set; } = string.Empty;
    public string CustomerEmail { get; set; } = string.Empty;
    public string CustomerPhone { get; set; } = string.Empty;
    public string DeliveryCity { get; set; } = string.Empty;
    public string DeliveryDistrict { get; set; } = string.Empty;
    public string DeliveryNeighborhood { get; set; } = string.Empty;
    public string DeliveryAddressLine { get; set; } = string.Empty;
    public string PostalCode { get; set; } = string.Empty;
    public string AddressTitle { get; set; } = string.Empty;
    public string? OrderNote { get; set; }
    public string PaymentMethod { get; set; } = string.Empty;
    public decimal TotalAmount { get; set; }
    public OrderStatus Status { get; set; }
    public DateTime CreatedAtUtc { get; set; }
    public List<OrderCreateResponseItemDto> Items { get; set; } = new();
}

public class OrderCreateResponseItemDto
{
    public int Id { get; set; }
    public int? ProductId { get; set; }
    public string ProductTitle { get; set; } = string.Empty;
    public decimal UnitPrice { get; set; }
    public int Quantity { get; set; }
}

public class SalesListItemDto
{
    public int OrderId { get; set; }
    public string CustomerName { get; set; } = string.Empty;
    public string CustomerEmail { get; set; } = string.Empty;
    public int ItemsCount { get; set; }
    public int TotalQuantity { get; set; }
    public decimal TotalAmount { get; set; }
    public DateTime CreatedAtUtc { get; set; }
    public string Status { get; set; } = string.Empty;
    public List<SalesItemDetailDto> Items { get; set; } = new();
}

public class SalesItemDetailDto
{
    public string ProductTitle { get; set; } = string.Empty;
    public int Quantity { get; set; }
    public decimal UnitPrice { get; set; }
    public decimal LineTotal { get; set; }
}

public class DashboardMetricsDto
{
    public int TotalProducts { get; set; }
    public int TotalSalesCount { get; set; }
    public decimal TotalRevenue { get; set; }
    public List<DashboardStatusItemDto> StatusDistribution { get; set; } = new();
    public List<DashboardRecentSaleDto> RecentSales { get; set; } = new();
}

public class DashboardStatusItemDto
{
    public string Status { get; set; } = string.Empty;
    public int Count { get; set; }
}

public class DashboardRecentSaleDto
{
    public int OrderId { get; set; }
    public int? ProductId { get; set; }
    public string ProductTitle { get; set; } = string.Empty;
    public int Quantity { get; set; }
    public decimal UnitPrice { get; set; }
    public decimal LineTotal { get; set; }
    public DateTime SoldAtUtc { get; set; }
    public string CustomerName { get; set; } = string.Empty;
    public string Status { get; set; } = string.Empty;
}
