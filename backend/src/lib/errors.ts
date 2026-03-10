export class ApiError extends Error {
  statusCode: number;
  code: string;

  constructor(statusCode: number, code: string, message: string) {
    super(message);
    this.statusCode = statusCode;
    this.code = code;
  }
}

export const badRequest = (code: string, message: string) => new ApiError(400, code, message);
export const unauthorized = (message = "Unauthorized") => new ApiError(401, "UNAUTHORIZED", message);
export const notFound = (entity: string) => new ApiError(404, "NOT_FOUND", `${entity} not found`);
export const conflict = (code: string, message: string) => new ApiError(409, code, message);
