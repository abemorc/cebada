
# ============================================================
# Exportar estructura del proyecto a Markdown
# Formato: |-- archivo o carpeta
# ============================================================

# Directorio raíz del proyecto
root <- "."

# Archivo de salida
output <- file.path("ai_context", "estructura-proyecto.md")

# Elementos que se excluirán
exclude <- c(
  ".venv",
  "venv",
  ".git",
  ".pytest_cache",
  ".mypy_cache",
  "__pycache__",
  ".Rproj.user",
  "node_modules",
  "renv"
)

# Función recursiva para generar el árbol
generate_tree <- function(path, prefix = "") {

  items <- list.files(
    path = path,
    all.files = FALSE,
    full.names = TRUE,
    recursive = FALSE,
    include.dirs = TRUE
  )

  # Excluir carpetas y archivos indicados
  items <- items[!basename(items) %in% exclude]

  # Ordenar primero las carpetas y después los archivos
  items <- items[
    order(!dir.exists(items), tolower(basename(items)))
  ]

  result <- character()

  for (item in items) {

    # Rama con símbolos ASCII
    result <- c(
      result,
      paste0(prefix, "|-- ", basename(item))
    )

    # Recorrer subcarpetas
    if (dir.exists(item)) {
      result <- c(
        result,
        generate_tree(
          path = item,
          prefix = paste0(prefix, "|   ")
        )
      )
    }
  }

  result
}

# Crear el árbol
tree <- c(
  basename(normalizePath(root)),
  generate_tree(root)
)

# Crear encabezado Markdown
content <- c(
  "# Estructura del proyecto FIRA-Cebada",
  "",
  "```text",
  tree,
  "```",
  ""
)

# Crear carpeta de destino si no existe
dir.create(
  dirname(output),
  recursive = TRUE,
  showWarnings = FALSE
)

# Exportar archivo
writeLines(content, output, useBytes = TRUE)

message(
  "Árbol exportado correctamente a: ",
  normalizePath(output, winslash = "/", mustWork = FALSE)
)
