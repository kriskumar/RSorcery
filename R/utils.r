
# Set verbosity level for RSorcerer
set_RSorcerer_verbose <- function(value = FALSE) {
  options(RSorcerer.verbose = value)
}

# Get the current verbosity setting for RSorcerer
get_RSorcerer_verbose <- function() {
  return(getOption("RSorcerer.verbose", default = FALSE))
}


#Takes a test input file and generates an object with the prompt and arguments
#' Internal utility function
#'
#' This function is for internal package use only
#' @keywords internal
extract_function_info <- function(file_path) {
  # Read lines from the file
  lines <- readLines(file_path)
  
  # Initialize a list to hold the information
  functions_info <- list()
  
  # Loop through the lines
  for (i in 2:length(lines)) {
    # Check if the line is a function definition
    if (grepl(".*<-\\s*function", lines[i])) {
      func_name <- gsub(".*<-\\s*function.*", "", lines[i])
      func_name <- gsub("\\s+", "", func_name)  # Remove any whitespace
      func_args_str <- gsub(".*function\\((.*)\\).*", "\\1", lines[i])
      
      # Check if the previous line is a comment (LLM prompt)
      if (grepl("^#", lines[i - 1])) {
        prompt <- substring(lines[i - 1], 2) # Remove the '#' character
        
        # Parse the arguments and their types
        args <- strsplit(func_args_str, ",\\s*")[[1]]
        args_types <- lapply(args, function(arg) {
          arg_parts <- strsplit(arg, "=")[[1]]
          arg_name <- trimws(arg_parts[1])
          arg_default_value <- ifelse(length(arg_parts) > 1, trimws(arg_parts[2]), NA)
          arg_type <- if (!is.na(arg_default_value)) class(eval(parse(text=arg_default_value))) else NA
          list(name = arg_name, type = arg_type)
        })
        
        # Create an entry in the list
        functions_info[[func_name]] <- list(
          prompt = prompt,
          arguments = args_types
        )
      }
    }
  }
  
  return(functions_info)
}

#call llm

#' Internal utility function
#'
#' This function is for internal package use only
#' @keywords internal
llmCall<-function(userquestion, model = "gpt-3.5-turbo")
{
sysprompt<-"You are the best R programmer. You will be given a user request to generate R function. 
Do not provide any other information just return the function code that does what is specified by the prompt
use the argument names with the types. The format of the result should start with 'RCode:[function name]' and provide
only the functions no comments."

chat.result<-create_chat_completion(
  model = model,
  messages = list(
    list(
      "role" = "system",
      "content" = sysprompt
    ),
    list(
      "role" = "user",
      "content" = userquestion
    )
  )
)
return(llmgenerated_functions<-chat.result$choices$message.content)
}


#' Internal utility function
#'
#' This function is for internal package use only
#' @keywords internal
generate_llm_prompt <- function(functions_info) {
  num_functions <- length(functions_info)
  intro_text <- ifelse(num_functions > 1, 
                       paste("Write", num_functions, "functions:"), 
                       "Write a function:")
  
  prompt_list <- lapply(seq_along(functions_info), function(idx) {
    func_info <- functions_info[[idx]]
    prompt <- func_info$prompt
    args <- func_info$arguments
    
    args_text <- lapply(args, function(arg) {
      paste(arg$name, "is a", arg$type)
    })
    
    func_intro <- ifelse(num_functions > 1, paste("\n\nFunction", idx, ":"), "")
    full_prompt <- paste(func_intro, "To", prompt, 
                         ". The function arguments are:", 
                         paste(unlist(args_text), collapse=", "), 
                         ".")
    return(full_prompt)
  })
  
  # Combine intro text with all prompts
  full_llm_prompt <- paste(intro_text, paste(unlist(prompt_list), collapse=" "))
  return(full_llm_prompt)
}

# 
# 
# # Example usage
# full_llm_prompt <- generate_llm_prompt(functions_info)
# print(full_llm_prompt)


#' Internal utility function
#'
#' This function is for internal package use only
#' @keywords internal
extract_function_code <- function(input_string) {
  # Regular expression to match the code block
  pattern <- "```R\\n(.*?)\\n```"
  
  # Use regmatches and regexpr to extract the code block
  matches <- regmatches(input_string, regexec(pattern, input_string, perl = TRUE))
  
  # Extract the code if a match is found
  if (length(matches) > 0 && length(matches[[1]]) > 1) {
    code_block <- matches[[1]][2]
    return(code_block)
  } else {
    return("No code block found")
  }
}


extract_and_write_functions <- function(input_string, functions_info, output_file, overwrite = FALSE) {
  # Regular expression to find all function blocks starting with "RCode:" and exclude "RCode:"
  pattern <- "RCode:([\\s\\S]*?)(?=\\n\\nRCode:|$)"
  
  # Use regmatches and gregexpr to extract all matches
  matches <- regmatches(input_string, gregexpr(pattern, input_string, perl = TRUE))
  
  # Flatten the list of matches and remove any empty strings
  function_blocks <- unlist(matches)
  function_blocks <- function_blocks[function_blocks != ""]
  
  # Process each function block to remove "RCode:" prefix from the first line
  processed_blocks <- lapply(function_blocks, function(block) {
    block_lines <- unlist(strsplit(block, "\n"))
    block_lines[1] <- gsub("^RCode:", "", block_lines[1])  # Replace "RCode:" with empty string
    paste(block_lines, collapse = "\n")
  })
  
  # Prepend each function with its prompt as a comment
  for (i in seq_along(processed_blocks)) {
    prompt_comment <- paste0("# ", functions_info[[i]]$prompt, "\n")
    processed_blocks[i] <- paste0(prompt_comment, processed_blocks[[i]])
  }
  
  # Open file connection with appropriate mode
  file_conn <- file(output_file, ifelse(overwrite, "w", "a"))
  
  # Write or append to the file
  writeLines(unlist(processed_blocks), file_conn, sep = "\n\n", useBytes = TRUE)
  close(file_conn)
  
  # Message to indicate completion
  message <- if (overwrite) "Functions written to" else "Functions appended to"
  
  cat(message, output_file, "\n")
}



# # Example usage
# file_path <- "test.r"
# prompts <- extract_llm_prompts(file_path)
# print(prompts)
#' Internal utility function
#'
#' This function is for internal package use only
#' @keywords internal
extract_llm_prompts <- function(file_path) {
  # Read lines from file
  lines <- readLines(file_path)
  
  # Initialize a list to hold function names and their prompts
  prompts <- list()
  
  # Loop through the lines
  for (i in 2:length(lines)) {
    # Check if the line is a function definition
    if (grepl(".*<-\\s*function", lines[i])) {
      func_name <- strsplit(lines[i], "<-\\s*function")[[1]][1]
      func_name <- gsub("\\s+", "", func_name) # Remove any whitespace
      
      # Check if the previous line is a comment
      if (grepl("^#", lines[i - 1])) {
        prompt <- substring(lines[i - 1], 2) # Remove the '#' character
        prompts[[func_name]] <- prompt
      }
    }
  }
  
  return(prompts)
}

#' Takes a file with a list of function definitions which are preceded
#' by a comment line with what the function does.
#' This function is exported and available to users.
#' @export
dosorcery <- function(file_path, output_file = NULL) {
  
  file_path_without_ext <- sub("\\.r$", "", file_path)
  
  # Set default for output_file if not provided
  if (is.null(output_file)) {
    output_file <- paste0(file_path_without_ext, "_extracted.r")
  }  
  
  functions_info <- extract_function_info(file_path)
  if (get_RSorcerer_verbose()) {
    print(functions_info)
  }
  userquestion<-generate_llm_prompt(functions_info)
  if (get_RSorcerer_verbose()) {
    print(userquestion)
  }
  llmgenerated_functions<-llmCall(userquestion)  
  
  extract_and_write_functions(llmgenerated_functions,functions_info,output_file = output_file,overwrite = TRUE)
}


