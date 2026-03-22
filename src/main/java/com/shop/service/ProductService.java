package com.shop.service;

import com.shop.entity.Product;
import com.shop.util.CsvUtil;
import org.springframework.stereotype.Service;

import java.util.List;

@Service
public class ProductService {

    private final CsvUtil csvUtil;

    public ProductService(CsvUtil csvUtil) {
        this.csvUtil = csvUtil;
    }

    public List<Product> getAllProducts() {
        return csvUtil.readAllProducts();
    }

    public Product getProductById(Long id) {
        return csvUtil.findProductById(id);
    }

    public void addProduct(Product product) {
        csvUtil.addProduct(product);
    }

    public void updateProduct(Product product) {
        csvUtil.updateProduct(product);
    }

    public void deleteProduct(Long id) {
        csvUtil.deleteProduct(id);
    }

    public boolean reduceStock(Long productId, Integer quantity) {
        Product product = csvUtil.findProductById(productId);
        if (product == null || product.getStock() < quantity) {
            return false;
        }
        product.setStock(product.getStock() - quantity);
        csvUtil.updateProduct(product);
        return true;
    }
}
