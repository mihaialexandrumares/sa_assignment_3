package org.example.structural.service;

import org.example.structural.entity.Book;

public interface BookDecorator {
    String getDescription();
    double getPrice();
}

class BasicBook implements BookDecorator {
    private Book book;

    public BasicBook(Book book) {
        this.book = book;
    }

    public String getDescription() {
        return book.getDescription();
    }

    public double getPrice() {
        return book.getPrice();
    }
}

abstract class BookDecoratorBase implements BookDecorator {
    protected BookDecorator decoratedBook;

    public BookDecoratorBase(BookDecorator book) {
        this.decoratedBook = book;
    }
}

class FeaturedBookDecorator extends BookDecoratorBase {

    public FeaturedBookDecorator(BookDecorator book) {
        super(book);
    }

    public String getDescription() {
        return "[FEATURED] " + decoratedBook.getDescription();
    }

    public double getPrice() {
        return decoratedBook.getPrice();
    }
}

class BestsellerBookDecorator extends BookDecoratorBase {

    public BestsellerBookDecorator(BookDecorator book) {
        super(book);
    }

    public String getDescription() {
        return "[BESTSELLER] " + decoratedBook.getDescription();
    }

    public double getPrice() {
        return decoratedBook.getPrice() * 1.1;
    }
}
