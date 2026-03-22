package com.shop.service;

import com.shop.entity.Order;
import com.shop.entity.Product;
import com.shop.entity.User;
import com.shop.util.CsvUtil;
import org.springframework.stereotype.Service;

import java.math.BigDecimal;
import java.util.List;

@Service
public class OrderService {

    private final CsvUtil csvUtil;
    private final ProductService productService;

    public OrderService(CsvUtil csvUtil, ProductService productService) {
        this.csvUtil = csvUtil;
        this.productService = productService;
    }

    public List<Order> getAllOrders() {
        return csvUtil.readAllOrders();
    }

    public List<Order> getOrdersByUserId(Long userId) {
        return csvUtil.findOrdersByUserId(userId);
    }

    public void createOrder(User user, Long productId, Integer quantity) {
        Product product = productService.getProductById(productId);
        if (product == null) {
            throw new RuntimeException("商品不存在");
        }
        if (product.getStock() < quantity) {
            throw new RuntimeException("库存不足");
        }

        // 扣减库存
        boolean success = productService.reduceStock(productId, quantity);
        if (!success) {
            throw new RuntimeException("库存不足");
        }

        // 创建订单
        Order order = new Order();
        order.setUserId(user.getId());
        order.setUsername(user.getUsername());
        order.setProductId(productId);
        order.setProductName(product.getName());
        order.setQuantity(quantity);
        order.setTotalPrice(product.getPrice().multiply(BigDecimal.valueOf(quantity)));
        
        csvUtil.addOrder(order);
    }
}
