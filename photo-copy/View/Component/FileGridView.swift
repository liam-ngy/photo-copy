import SwiftUI

struct FileGridView: View {
  let files: [String]
  let iconName: String
  let iconColor: Color
  let textColor: Color
  
  init(
    files: [String],
    iconName: String = "photo",
    iconColor: Color = .blue,
    textColor: Color = .primary
  ) {
    self.files = files
    self.iconName = iconName
    self.iconColor = iconColor
    self.textColor = textColor
  }
  
  var body: some View {
    LazyVGrid(columns: [GridItem(.adaptive(minimum: 120))],
              alignment: .leading,
              spacing: 8) {
      ForEach(files, id: \.self) { file in
        HStack(spacing: 8) {
          Image(systemName: iconName)
            .foregroundColor(iconColor)
          Text(file)
            .font(.system(.body, design: .monospaced))
            .lineLimit(1)
            .truncationMode(.middle)
            .foregroundColor(textColor)
        }
      }
    }
  }
}
