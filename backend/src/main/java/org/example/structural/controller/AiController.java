package org.example.structural.controller;

import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import org.example.structural.entity.Book;
import org.example.structural.service.LibraryFacade;
import org.example.structural.service.OllamaService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Map;
import java.util.stream.Collectors;

@RestController
@RequestMapping("/api/ai")
@Tag(name = "AI Assistant", description = "Endpoints for interacting with Ollama")
public class AiController {

    @Autowired
    private OllamaService ollamaService;

    @Autowired
    private LibraryFacade libraryFacade;

    @PostMapping("/ask")
    @Operation(summary = "Ask AI", description = "Chat with AI that knows the library inventory")
    public Map<String, String> askAi(@RequestBody Map<String, String> payload) {
        String userPrompt = payload.get("prompt");
        
        String libraryInventory = getFormattedBookList();

        String systemContext = String.format(
                "You are a helpful library assistant. " +
                        "You have access to the following books in the library catalog: [%s]. " +
                        "Answer the user's questions based on this catalog. " +
                        "If they ask for a recommendation, pick strictly from this list.",
                libraryInventory
        );

        String aiResponse = ollamaService.generateResponse(userPrompt, systemContext);

        return Map.of("answer", aiResponse);
    }

    private String getFormattedBookList() {
        List<Book> books = libraryFacade.getAllBooks();
        if (books.isEmpty()) {
            return "No books currently available.";
        }
        return books.stream()
                .map(b -> String.format("\"%s\" by %s ($%.2f)", b.getTitle(), b.getAuthor(), b.getPrice()))
                .collect(Collectors.joining("; "));
    }
}