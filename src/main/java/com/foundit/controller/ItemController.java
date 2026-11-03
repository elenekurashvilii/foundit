
package com.foundit.controller;

import com.foundit.model.Item;
import com.foundit.service.ItemService;
import org.springframework.http.HttpStatus;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/items")
public class ItemController {

    private final ItemService itemService;

    public ItemController(ItemService itemService) {
        this.itemService = itemService;
    }

    @GetMapping
    public List<Item> getItems(
            @RequestParam(required = false) String search,
            @RequestParam(required = false) String type) {

        List<Item> results = itemService.searchItems(search);

        if (type != null && !type.isBlank()) {
            results = results.stream()
                    .filter(item -> item.getType().equalsIgnoreCase(type))
                    .toList();
        }

        return results;
    }

    @GetMapping("/{id}")
    public Item getItem(@PathVariable Long id) {
        return itemService.getItemById(id)
                .orElseThrow(() ->
                        new org.springframework.web.server.ResponseStatusException(
                                HttpStatus.NOT_FOUND, "Item not found"));
    }

    @PostMapping
    @ResponseStatus(HttpStatus.CREATED)
    public Item createItem(@RequestBody Item item) {
        return itemService.addItem(
                item.getName(),
                item.getDescription(),
                item.getLocation(),
                item.getType()
        );
    }

    @PutMapping("/{id}/return")
    public Item markReturned(@PathVariable Long id) {
        if (!itemService.markAsReturned(id)) {
            throw new org.springframework.web.server.ResponseStatusException(
                    HttpStatus.NOT_FOUND, "Item not found");
        }

        return itemService.getItemById(id).orElseThrow();
    }

    @DeleteMapping("/{id}")
    @ResponseStatus(HttpStatus.NO_CONTENT)
    public void deleteItem(@PathVariable Long id) {
        if (!itemService.deleteItem(id)) {
            throw new org.springframework.web.server.ResponseStatusException(
                    HttpStatus.NOT_FOUND, "Item not found");
        }
    }
}
