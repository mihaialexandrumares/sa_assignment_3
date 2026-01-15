package org.example.structural.controller;

import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import org.example.structural.dto.BookDto;
import org.example.structural.entity.Book;
import org.example.structural.service.LibraryFacade;
import org.example.structural.utils.BookMapper;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Controller;
import org.springframework.ui.Model;
import org.springframework.web.bind.annotation.*;

import java.util.ArrayList;
import java.util.List;
import java.util.stream.Collectors;

@Controller
public class LibraryController {

    @Autowired
    private LibraryFacade libraryFacade;

    private List<String> logs = new ArrayList<>();

    @GetMapping("/")
    public String home(Model model) {
        model.addAttribute("books", libraryFacade.getAllBooks());
        model.addAttribute("featuredBooks", libraryFacade.getFeaturedBooks());
        model.addAttribute("logs", logs);
        return "index";
    }

    @PostMapping("/book")
    public String addBook(@RequestParam String title,
                          @RequestParam String author,
                          @RequestParam double price,
                          Model model) {
        logs.clear();
        logs.add("[FACADE] LibraryFacade.addBook() called");
        Book book = new Book();
        book.setTitle(title);
        book.setAuthor(author);
        book.setPrice(price);
        libraryFacade.addBook(book);
        logs.add("[FACADE] Book added through facade");
        logs.add("[DECORATOR] Applying FeaturedBookDecorator to display");

        model.addAttribute("books", libraryFacade.getAllBooks());
        model.addAttribute("featuredBooks", libraryFacade.getFeaturedBooks());
        model.addAttribute("logs", logs);
        return "index";
    }

    @PostMapping("/book/delete/{id}")
    public String deleteBook(@PathVariable Long id, Model model) {
        logs.clear();
        logs.add("[FACADE] LibraryFacade.deleteBook() called");
        libraryFacade.deleteBook(id);
        logs.add("[FACADE] Book deleted through facade");

        model.addAttribute("books", libraryFacade.getAllBooks());
        model.addAttribute("featuredBooks", libraryFacade.getFeaturedBooks());
        model.addAttribute("logs", logs);
        return "index";
    }
}

@RestController
@RequestMapping("/api/books")
@Tag(name = "Library API", description = "Book management using Structural Design Patterns")
class LibraryRestController {

    @Autowired
    private LibraryFacade libraryFacade;

    @GetMapping
    @Operation(summary = "Get all books", description = "Uses FACADE pattern")
    public List<BookDto> getAllBooks() {
        return libraryFacade.getAllBooks().stream()
                .map(BookMapper::toDTO)
                .collect(Collectors.toList());
    }

    @GetMapping("/{id}")
    @Operation(summary = "Get book by ID", description = "Uses FACADE pattern")
    public BookDto getBookById(@PathVariable Long id) {
        Book book = libraryFacade.getBook(id);
        return book != null ? BookMapper.toDTO(book) : null;
    }

    @PostMapping
    @Operation(summary = "Add a new book", description = "Uses FACADE pattern")
    public BookDto addBook(@RequestBody BookDto bookDto) {
        Book book = BookMapper.toEntity(bookDto);
        libraryFacade.addBook(book);
        return bookDto;
    }

    @DeleteMapping("/{id}")
    @Operation(summary = "Delete a book", description = "Uses FACADE pattern")
    public void deleteBook(@PathVariable Long id) {
        libraryFacade.deleteBook(id);
    }

    @GetMapping("/featured")
    @Operation(summary = "Get featured books", description = "Uses DECORATOR pattern")
    public List<String> getFeaturedBooks() {
        return libraryFacade.getFeaturedBooks();
    }

    @GetMapping("/bestsellers")
    @Operation(summary = "Get bestseller books", description = "Uses DECORATOR pattern with 10% markup")
    public List<String> getBestsellerBooks() {
        return libraryFacade.getBestsellerBooks();
    }
}