export function recordAuthor(author: string, authors: string[]) {
    authors = authors || []
    if (author && !authors.includes(author)) {
      authors.push(author)
    }
    return authors
}