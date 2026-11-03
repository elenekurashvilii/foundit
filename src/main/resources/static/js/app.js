const API_URL = "/api/items";

let currentFilter = "ALL";
let searchTimeout;

const itemsGrid = document.getElementById("items-grid");
const itemCount = document.getElementById("item-count");
const searchInput = document.getElementById("search-input");
const emptyState = document.getElementById("empty-state");
const reportForm = document.getElementById("report-form");
const formMessage = document.getElementById("form-message");

function getItemEmoji(item) {
    const text = `${item.name || ""} ${item.description || ""}`.toLowerCase();

    if (text.includes("key")) return "🔑";
    if (text.includes("phone")) return "📱";
    if (text.includes("headphone") || text.includes("earbud")) return "🎧";
    if (text.includes("bag") || text.includes("backpack")) return "👜";
    if (text.includes("wallet")) return "👛";
    if (text.includes("watch")) return "⌚";
    if (text.includes("book")) return "📚";
    if (text.includes("laptop") || text.includes("computer")) return "💻";
    if (text.includes("card")) return "💳";
    if (text.includes("glasses")) return "👓";

    return "📦";
}

async function loadItems() {
    const params = new URLSearchParams();

    const search = searchInput.value.trim();

    if (search) {
        params.append("search", search);
    }

    if (currentFilter !== "ALL") {
        params.append("type", currentFilter);
    }

    itemsGrid.innerHTML = '<div class="loading-message">Finding your items...</div>';
    emptyState.classList.add("hidden");

    try {
        const response = await fetch(`${API_URL}?${params.toString()}`);

        if (!response.ok) {
            throw new Error("Could not load items.");
        }

        const items = await response.json();

        itemCount.textContent = items.length;
        displayItems(items);

    } catch (error) {
        itemsGrid.innerHTML =
            '<div class="loading-message">Unable to load items. Please refresh the page.</div>';
        itemCount.textContent = "0";
        console.error(error);
    }
}

function displayItems(items) {
    itemsGrid.innerHTML = "";

    if (!items || items.length === 0) {
        emptyState.classList.remove("hidden");
        return;
    }

    emptyState.classList.add("hidden");

    items.forEach(item => {
        const card = document.createElement("article");
        card.className = "item-card";

        const top = document.createElement("div");
        top.className = "item-card-top";

        const emoji = document.createElement("span");
        emoji.className = "item-emoji";
        emoji.textContent = getItemEmoji(item);

        const badge = document.createElement("span");
        const type = (item.type || "").toUpperCase();
        badge.className = `item-badge ${type.toLowerCase()}`;
        badge.textContent = type;

        top.append(emoji, badge);

        const name = document.createElement("h3");
        name.textContent = item.name || "Unnamed item";

        const description = document.createElement("p");
        description.className = "item-description";
        description.textContent = item.description || "No description provided.";

        const location = document.createElement("div");
        location.className = "item-location";
        location.textContent = `📍 ${item.location || "Location not specified"}`;

        card.append(top, name, description, location);

        if (item.status === "ACTIVE") {
            const returnButton = document.createElement("button");
            returnButton.className = "return-button";
            returnButton.textContent = "✓ Mark as returned";

            returnButton.addEventListener("click", () => {
                markAsReturned(item.id);
            });

            card.appendChild(returnButton);
        } else {
            const returned = document.createElement("div");
            returned.className = "returned-label";
            returned.textContent = "✓ Successfully returned";
            card.appendChild(returned);
        }

        itemsGrid.appendChild(card);
    });
}

function filterItems(filter) {
    currentFilter = filter;

    document.querySelectorAll(".filter-button").forEach(button => {
        button.classList.toggle(
            "active",
            button.dataset.filter === filter
        );
    });

    loadItems();
}

document.querySelectorAll(".filter-button").forEach(button => {
    button.addEventListener("click", () => {
        filterItems(button.dataset.filter);
    });
});

searchInput.addEventListener("input", () => {
    clearTimeout(searchTimeout);
    searchTimeout = setTimeout(loadItems, 250);
});

async function markAsReturned(id) {
    try {
        const response = await fetch(`${API_URL}/${id}/return`, {
            method: "PUT"
        });

        if (!response.ok) {
            throw new Error("Could not update item.");
        }

        await loadItems();

    } catch (error) {
        alert("Something went wrong. Please try again.");
        console.error(error);
    }
}

reportForm.addEventListener("submit", async event => {
    event.preventDefault();

    const formData = new FormData(reportForm);

    const newItem = {
        name: formData.get("name").trim(),
        description: formData.get("description").trim(),
        location: formData.get("location").trim(),
        type: formData.get("type")
    };

    if (!newItem.name || !newItem.location) {
        showMessage("Please enter the item name and location.", "error");
        return;
    }

    const submitButton = reportForm.querySelector(".submit-button");
    submitButton.disabled = true;
    submitButton.textContent = "Publishing...";

    try {
        const response = await fetch(API_URL, {
            method: "POST",
            headers: {
                "Content-Type": "application/json"
            },
            body: JSON.stringify(newItem)
        });

        if (!response.ok) {
            const errorText = await response.text();
            throw new Error(errorText || "Could not publish listing.");
        }

        reportForm.reset();
        searchInput.value = "";
        currentFilter = "ALL";

        document.querySelectorAll(".filter-button").forEach(button => {
            button.classList.toggle(
                "active",
                button.dataset.filter === "ALL"
            );
        });

        showMessage("Your listing has been published successfully!", "success");

        await loadItems();

        document.getElementById("browse").scrollIntoView({
            behavior: "smooth"
        });

    } catch (error) {
        showMessage("Unable to publish your listing. Please try again.", "error");
        console.error(error);

    } finally {
        submitButton.disabled = false;
        submitButton.innerHTML = 'Publish listing <span>↗</span>';
    }
});

function showMessage(message, type) {
    formMessage.textContent = message;
    formMessage.className = `form-message ${type}`;
}

loadItems();
