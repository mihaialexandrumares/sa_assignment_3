package org.example.structural.service;

import org.example.structural.entity.Book;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Component;

import java.util.ArrayList;
import java.util.List;

@Component
public class LibraryFacade {
    @Autowired
    private BookService bookService;

    public void addBook(Book book) {
        bookService.addBook(book);
    }

    public List<Book> getAllBooks() {
        return bookService.getAllBooks();
    }

    public Book getBook(Long id) {
        return bookService.getBookById(id).orElse(null);
    }

    public void updateBook(Long id, Book book) {
        bookService.updateBook(id, book);
    }

    public void deleteBook(Long id) {
        bookService.deleteBook(id);
    }

    public List<String> getFeaturedBooks() {
        List<String> result = new ArrayList<>();
        for (Book book : bookService.getAllBooks()) {
            BookDecorator decorated = new FeaturedBookDecorator(new BasicBook(book));
            result.add(decorated.getDescription() + " - $" + decorated.getPrice());
        }
        return result;
    }

    public List<String> getBestsellerBooks() {
        List<String> result = new ArrayList<>();
        for (Book book : bookService.getAllBooks()) {
            BookDecorator decorated = new BestsellerBookDecorator(new BasicBook(book));
            result.add(decorated.getDescription() + " - $" + decorated.getPrice());
        }
        return result;
    }
}
