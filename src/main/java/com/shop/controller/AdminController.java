package com.shop.controller;

import com.shop.entity.Order;
import com.shop.entity.Product;
import com.shop.entity.User;
import com.shop.service.OrderService;
import com.shop.service.ProductService;
import com.shop.service.UserService;
import org.springframework.http.ResponseEntity;
import org.springframework.stereotype.Controller;
import org.springframework.ui.Model;
import org.springframework.web.bind.annotation.*;

import javax.servlet.http.HttpSession;
import java.math.BigDecimal;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

@Controller
public class AdminController {

    private final UserService userService;
    private final ProductService productService;
    private final OrderService orderService;

    public AdminController(UserService userService, ProductService productService, OrderService orderService) {
        this.userService = userService;
        this.productService = productService;
        this.orderService = orderService;
    }

    @GetMapping("/admin")
    public String adminPage(HttpSession session, Model model) {
        if (!userService.isAdmin(session)) {
            return "redirect:/login";
        }
        User user = userService.getCurrentUser(session);
        model.addAttribute("user", user);
        return "admin";
    }

    // ==================== 商品管理 ====================

    @GetMapping("/api/admin/products")
    @ResponseBody
    public ResponseEntity<?> getAllProducts(HttpSession session) {
        if (!userService.isAdmin(session)) {
            Map<String, Object> result = new HashMap<>();
            result.put("success", false);
            result.put("message", "无权限");
            return ResponseEntity.ok(result);
        }
        List<Product> products = productService.getAllProducts();
        return ResponseEntity.ok(products);
    }

    @PostMapping("/api/admin/products")
    @ResponseBody
    public ResponseEntity<?> addProduct(@RequestParam String name,
                                        @RequestParam String description,
                                        @RequestParam BigDecimal price,
                                        @RequestParam Integer stock,
                                        HttpSession session) {
        Map<String, Object> result = new HashMap<>();
        if (!userService.isAdmin(session)) {
            result.put("success", false);
            result.put("message", "无权限");
            return ResponseEntity.ok(result);
        }

        Product product = new Product();
        product.setName(name);
        product.setDescription(description);
        product.setPrice(price);
        product.setStock(stock);
        productService.addProduct(product);
        
        result.put("success", true);
        result.put("message", "添加成功");
        return ResponseEntity.ok(result);
    }

    @PutMapping("/api/admin/products/{id}")
    @ResponseBody
    public ResponseEntity<?> updateProduct(@PathVariable Long id,
                                           @RequestParam String name,
                                           @RequestParam String description,
                                           @RequestParam BigDecimal price,
                                           @RequestParam Integer stock,
                                           HttpSession session) {
        Map<String, Object> result = new HashMap<>();
        if (!userService.isAdmin(session)) {
            result.put("success", false);
            result.put("message", "无权限");
            return ResponseEntity.ok(result);
        }

        Product product = productService.getProductById(id);
        if (product == null) {
            result.put("success", false);
            result.put("message", "商品不存在");
            return ResponseEntity.ok(result);
        }

        product.setName(name);
        product.setDescription(description);
        product.setPrice(price);
        product.setStock(stock);
        productService.updateProduct(product);
        
        result.put("success", true);
        result.put("message", "更新成功");
        return ResponseEntity.ok(result);
    }

    @DeleteMapping("/api/admin/products/{id}")
    @ResponseBody
    public ResponseEntity<?> deleteProduct(@PathVariable Long id, HttpSession session) {
        Map<String, Object> result = new HashMap<>();
        if (!userService.isAdmin(session)) {
            result.put("success", false);
            result.put("message", "无权限");
            return ResponseEntity.ok(result);
        }

        productService.deleteProduct(id);
        result.put("success", true);
        result.put("message", "删除成功");
        return ResponseEntity.ok(result);
    }

    // ==================== 订单管理 ====================

    @GetMapping("/api/admin/orders")
    @ResponseBody
    public ResponseEntity<?> getAllOrders(HttpSession session) {
        if (!userService.isAdmin(session)) {
            Map<String, Object> result = new HashMap<>();
            result.put("success", false);
            result.put("message", "无权限");
            return ResponseEntity.ok(result);
        }
        List<Order> orders = orderService.getAllOrders();
        return ResponseEntity.ok(orders);
    }
}
