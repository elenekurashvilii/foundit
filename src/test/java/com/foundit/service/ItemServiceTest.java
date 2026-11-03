
package com.foundit.service;

import com.foundit.model.Item;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;

import java.util.List;

import static org.junit.jupiter.api.Assertions.*;

class ItemServiceTest {

    private ItemService itemService;

    @BeforeEach
    void setUp() {
        itemService = new ItemService();
    }

    @Test
    void shouldAddNewItem() {
        Item item = itemService.addItem(
                "Wallet",
                "Black leather wallet",
                "University",
                "LOST"
        );

        assertNotNull(item);
        assertEquals("Wallet", item.getName());
        assertEquals("LOST", item.getType());
        assertEquals("ACTIVE", item.getStatus());
    }

    @Test
    void shouldGetAllItems() {
        List<Item> items = itemService.getAllItems();

        assertEquals(3, items.size());
    }

    @Test
    void shouldSearchItemsByName() {
        List<Item> results = itemService.searchItems("headphones");

        assertEquals(1, results.size());
        assertEquals("Wireless headphones", results.get(0).getName());
    }

    @Test
    void shouldFilterItemsByType() {
        List<Item> results = itemService.getItemsByType("LOST");

        assertEquals(2, results.size());
    }

    @Test
    void shouldMarkItemAsReturned() {
        boolean result = itemService.markAsReturned(1L);

        assertTrue(result);
        assertEquals(
                "RETURNED",
                itemService.getItemById(1L).orElseThrow().getStatus()
        );
    }

    @Test
    void shouldDeleteItem() {
        boolean result = itemService.deleteItem(1L);

        assertTrue(result);
        assertEquals(2, itemService.getAllItems().size());
    }

    @Test
    void shouldRejectEmptyItemName() {
        assertThrows(
                IllegalArgumentException.class,
                () -> itemService.addItem(
                        "", "Description", "University", "LOST"
                )
        );
    }

    @Test
    void shouldRejectInvalidItemType() {
        assertThrows(
                IllegalArgumentException.class,
                () -> itemService.addItem(
                        "Wallet", "Description", "University", "UNKNOWN"
                )
        );
    }
}
