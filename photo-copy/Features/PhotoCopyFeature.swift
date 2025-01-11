import Foundation
import ComposableArchitecture

// MARK: - PhotoCopyFeature

struct PhotoCopyFeature: Reducer {
    struct State: Equatable {
        var baseFolder: URL?
        var finalsFolder: URL?
        var paxFolder: URL?
        var destinationFolder: URL?
        var customerInput: String = ""
        var photoInput: String = ""
        var existingCustomers: [String] = []
        var copyState: CopyState = .idle
        var folderErrorMessages: [String] = []

        var hasValidCustomerInput: Bool {
            !customerInput.trimmingCharacters(in: .whitespaces).isEmpty
        }

        var canCreateCustomerDirectory: Bool {
            hasValidCustomerInput && paxFolder != nil
        }

        var isCustomerDirectoryCreated: Bool {
            destinationFolder != nil
        }

        var shouldShowCustomerInput: Bool {
            !isCustomerDirectoryCreated
        }

        var canProceedToPhotos: Bool {
            isCustomerDirectoryCreated
        }

        var hasFolderErrorMessages: Bool {
            !folderErrorMessages.isEmpty
        }

        enum CopyState: Equatable {
            case idle
            case copying
            case completed(FileCopyService.FileCopyResult)

            var isCopying: Bool {
                if case .copying = self {
                    return true
                }
                return false
            }
        }
    }

    // MARK: - Actions

    enum Action: Equatable {
        case folder(FolderAction)
        case customer(CustomerAction)
        case photo(PhotoAction)
        case resetState
    }

    // MARK: - Folder Actions

    enum FolderAction: Equatable {
        case setBaseFolder(URL)
        case setFinalsFolder(URL)
        case setPaxFolder(URL)
        case requiredFoldersFailed(folder: Folder, error: FileCopyService.FileCopyError)
        case clearFolderErrorMessages
    }

    // MARK: - Customer Actions

    enum CustomerAction: Equatable {
        case loadExistingCustomers(URL)
        case existingCustomersLoaded([String])
        case selectExistingCustomer(String)
        case updateCustomerInput(String)
        case createCustomerDirectory
        case customerDirectoryCreated(URL)
        case customerDirectoryFailed(FileCopyService.FileCopyError)
        case clearCustomer
    }

    // MARK: - Photo Actions

    enum PhotoAction: Equatable {
        case updatePhotoInput(String)
        case clearPhotoInput
        case copyPhotos
        case copyPhotosCompleted(FileCopyService.FileCopyResult)
    }

    @Dependency(\.fileManager) var fileManager

    var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {
            case .folder(let folderAction):
                return handleFolderAction(&state, folderAction)

            case .customer(let customerAction):
                return handleCustomerAction(&state, customerAction)

            case .photo(let photoAction):
                return handlePhotoAction(&state, photoAction)

            case .resetState:
                // Reset all properties to their default values
                state.baseFolder = nil
                state.finalsFolder = nil
                state.paxFolder = nil
                state.destinationFolder = nil
                state.customerInput = ""
                state.photoInput = ""
                state.existingCustomers = []
                state.copyState = .idle
                state.folderErrorMessages = []
                return .none
            }
        }
    }

    // MARK: - Folder Handling

    private func handleFolderAction(_ state: inout State, _ action: FolderAction) -> Effect<Action> {
        switch action {
        case let .setBaseFolder(url):
            state.baseFolder = url
            state.folderErrorMessages = [] // Clear previous errors when setting a new base folder

            return .run { send in
                let folders: [(Folder, (URL) -> Action)] = [
                    (.pax, { Action.folder(.setPaxFolder($0)) }),
                    (.finals, { Action.folder(.setFinalsFolder($0)) })
                ]

                for (folder, successAction) in folders {
                    switch await fileManager.getDirectory(url, folder.rawValue) {
                    case let .success(folderURL):
                        await send(successAction(folderURL))
                    case let .failure(error):
                        await send(.folder(.requiredFoldersFailed(folder: folder, error: error)))
                    }
                }
            }

        case let .setPaxFolder(url):
            state.paxFolder = url
            return .run { send in
                await send(.customer(.loadExistingCustomers(url)))
            }

        case let .setFinalsFolder(url):
            state.finalsFolder = url
            return .none

        case let .requiredFoldersFailed(folder, error):
            let errorMessage = "\(folder.rawValue.capitalized) Folder Error: \(error.localizedDescription)"
            state.folderErrorMessages.append(errorMessage)

            switch folder {
            case .pax:
                state.paxFolder = nil
            case .finals:
                state.finalsFolder = nil
            }

            return .none

        case .clearFolderErrorMessages:
            state.folderErrorMessages = []
            return .none
        }
    }

    // MARK: - Customer Handling

    private func handleCustomerAction(_ state: inout State, _ action: CustomerAction) -> Effect<Action> {
        switch action {
        case let .loadExistingCustomers(paxDir):
            state.folderErrorMessages = []
            return .run { send in
                switch await fileManager.listContents(paxDir) {
                case let .success(customers):
                    await send(.customer(.existingCustomersLoaded(customers)))
                case let .failure(error):
                    print(error)
                    await send(.folder(.requiredFoldersFailed(folder: .pax, error: error)))
                }
            }

        case let .existingCustomersLoaded(customers):
            state.existingCustomers = customers
            state.folderErrorMessages = []
            return .none

        case let .selectExistingCustomer(customer):
            guard let paxDir = state.paxFolder else { return .none }
            state.customerInput = customer
            return .run { send in
              await send(.photo(.clearPhotoInput))
                let result = await fileManager.getDirectory(paxDir, customer)
                switch result {
                case .success(let url):
                  await send(.customer(.customerDirectoryCreated(url)))
                case .failure(let error):
                  await send(.customer(.customerDirectoryFailed(error)))
                }
            }

        case let .updateCustomerInput(input):
            state.customerInput = input
            return .none

        case .createCustomerDirectory:
            guard let paxDir = state.paxFolder,
                  !state.customerInput.trimmingCharacters(in: .whitespaces).isEmpty else { return .none }

            state.copyState = .idle
            state.folderErrorMessages = []

            return .run { [customerInput = state.customerInput] send in
                let result = await fileManager.createDirectory(paxDir, customerInput)
                switch result {
                case .success(let url):
                  await send(.customer(.customerDirectoryCreated(url)))
                case .failure(let error):
                  await send(.customer(.customerDirectoryFailed(error)))
                }
            }

        case let .customerDirectoryCreated(url):
            state.destinationFolder = url
            state.folderErrorMessages = []

            if let paxDir = state.paxFolder {
                return .run { send in
                    await send(.customer(.loadExistingCustomers(paxDir)))
                }
            }

            return .none

        case .customerDirectoryFailed:
            return .none

        case .clearCustomer:
            state.customerInput = ""
            state.destinationFolder = nil
            state.folderErrorMessages = []
            state.copyState = .idle
            return .none
        }
    }

    // MARK: - Photo Handling

    private func handlePhotoAction(_ state: inout State, _ action: PhotoAction) -> Effect<Action> {
        switch action {
        case let .updatePhotoInput(input):
            state.photoInput = input
            return .none

        case .clearPhotoInput:
            state.photoInput = ""
            return .none

        case .copyPhotos:
            guard let source = state.finalsFolder,
                  let destination = state.destinationFolder else {
                state.copyState = .completed(.failure(.invalidSource))
                return .none
            }

            state.copyState = .copying

            switch PhotoInputParser.parseToFileNames(state.photoInput) {
            case .success(let photos):
                if photos.isEmpty {
                    state.copyState = .completed(.failure(.invalidPhotoRange))
                    return .none
                }

                return .run { send in
                    let result = await FileCopyService.copyFiles(
                        from: source,
                        to: destination,
                        files: photos
                    )
                    await send(.photo(.copyPhotosCompleted(result)))
                }

            case .failure:
                state.copyState = .completed(.failure(.invalidPhotoRange))
                return .none
            }

        case let .copyPhotosCompleted(result):
            state.copyState = .completed(result)
            return .none
        }
    }
}
