struct FileCopyMessageBuilder {
    static func buildMessage(for result: FileCopyService.FileCopyResponse) -> String {
      let builder = MessageBuilder()

        switch result {
        case .success(let copiedFiles):
            builder
              .addKeyValue("Successfully copied files", value: copiedFiles.joined(separator: ", "))
              .addKeyValue("Copied files count", value: "\(copiedFiles.count)")
          
        case .partialSuccess(let copiedFiles, let missingFiles):
            builder
              .addKeyValue("Successfully copied files", value: copiedFiles.joined(separator: ", "))
              .addKeyValue("Copied files count", value: "\(copiedFiles.count)")
              .addKeyValue("Files not found", value: missingFiles.joined(separator: ", "))
              .addKeyValue("Files not found count", value: "\(missingFiles.count)")
          
        case .failure(let error):
            builder
            .addLine(error.description)
        }

        return builder.build()
    }
}
