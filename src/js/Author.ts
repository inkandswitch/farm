export function recordAuthor(author: string, authors: string[] = []) {
    if (author && !authors.includes(author)) {
      authors.push(author)
    }
    return authors
}