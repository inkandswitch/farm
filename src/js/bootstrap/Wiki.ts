import Repo from "../Repo"
import * as Bs from "."

export function code(repo: Repo) {
  return Bs.code(repo, "Wiki.elm", {
    title: "Wiki",
    config: {
      article: Bs.code(repo, "Article.elm"),
      articleIndex: Bs.code(repo, "ArticleIndex.elm", {
        config: {
          articleIndexItem: Bs.code(repo, "ArticleIndexItem.elm"),
        },
      }),
    },
  })
}

export function data(repo: Repo) {
  const wikiArticle = repo.create({
    title: "Welcome",
    body: "This is the RealmWiki",
  })

  return repo.create({
    title: "RealmWiki",
    articles: [wikiArticle],
  })
}
