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
import java.util.HashMap;
import java.util.List;
import java.util.Map;

@Controller
public class UserController {

    private final UserService userService;
    private final ProductService productService;
    private final OrderService orderService;

    public UserController(UserService userService, ProductService productService, OrderService orderService) {
        this.userService = userService;
        this.productService = productService;
        this.orderService = orderService;
    }

    @GetMapping("/shop")
    public String shopPage(HttpSession session, Model model) {
        User user = userService.getCurrentUser(session);
        if (user == null) {
            return "redirect:/login";
        }
        model.addAttribute("user", user);
        return "shop";
    }

    @GetMapping("/api/products")
    @ResponseBody
    public ResponseEntity<?> getAllProducts() {
        List<Product> products = productService.getAllProducts();
        return ResponseEntity.ok(products);
    }

    @GetMapping("/api/my-orders")
    @ResponseBody
    public ResponseEntity<?> getMyOrders(HttpSession session) {
        User user = userService.getCurrentUser(session);
        if (user == null) {
            Map<String, Object> result = new HashMap<>();
            result.put("success", false);
            result.put("message", "请先登录");
            return ResponseEntity.ok(result);
        }
        List<Order> orders = orderService.getOrdersByUserId(user.getId());
        return ResponseEntity.ok(orders);
    }

    @PostMapping("/api/buy")
    @ResponseBody
    public ResponseEntity<?> buyProduct(@RequestParam Long productId,
                                        @RequestParam Integer quantity,
                                        HttpSession session) {
        Map<String, Object> result = new HashMap<>();
        User user = userService.getCurrentUser(session);
        if (user == null) {
            result.put("success", false);
            result.put("message", "请先登录");
            return ResponseEntity.ok(result);
        }
        
        try {
            orderService.createOrder(user, productId, quantity);
            result.put("success", true);
            result.put("message", "购买成功");
        } catch (Exception e) {
            result.put("success", false);
            result.put("message", e.getMessage());
        }
        return ResponseEntity.ok(result);
    }
}
