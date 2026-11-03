
package com.foundit.service;

import com.foundit.model.Item;
import org.springframework.stereotype.Service;

import java.util.ArrayList;
import java.util.List;
import java.util.Optional;

@Service
public class ItemService {

    private final List<Item> items = new ArrayList<>();
    private Long nextId = 1L;

    public ItemService() {
        addItem("Wireless headphones",
                "Black headphones in a case",
                "University library", "LOST");

        addItem("Brown leather bag",
                "Small brown leather bag",
                "City center", "FOUND");

        addItem("Set of keys",
                "Three keys with a blue keychain",
                "Bus station", "LOST");
    }

    public Item addItem(String name, String description,
                        String location, String type) {

        if (name == null || name.isBlank()) {
            throw new IllegalArgumentException("Item name is required");
        }

        if (location == null || location.isBlank()) {
            throw new IllegalArgumentException("Location is required");
        }

        if (!"LOST".equals(type) && !"FOUND".equals(type)) {
            throw new IllegalArgumentException("Type must be LOST or FOUND");
        }

        Item item = new Item(
                nextId++,
                name,
                description,
                location,
                type,
                "ACTIVE"
        );

        items.add(item);

        return item;
    }

    public List<Item> getAllItems() {
        return new ArrayList<>(items);
    }

    public Optional<Item> getItemById(Long id) {
        return items.stream()
                .filter(item -> item.getId().equals(id))
                .findFirst();
    }

    public List<Item> searchItems(String keyword) {
        if (keyword == null || keyword.isBlank()) {
            return getAllItems();
        }

        String search = keyword.toLowerCase();

        return items.stream()
                .filter(item ->
                        item.getName().toLowerCase().contains(search)
                        || item.getLocation().toLowerCase().contains(search)
                )
                .toList();
    }

    public List<Item> getItemsByType(String type) {
        if (type == null || type.isBlank()) {
            return getAllItems();
        }

        return items.stream()
                .filter(item -> item.getType().equalsIgnoreCase(type))
                .toList();
    }

    public boolean markAsReturned(Long id) {
        Optional<Item> item = getItemById(id);

        if (item.isEmpty()) {
            return false;
        }

        item.get().setStatus("RETURNED");
        return true;
    }

    public boolean deleteItem(Long id) {
        return items.removeIf(item -> item.getId().equals(id));
    }
}
