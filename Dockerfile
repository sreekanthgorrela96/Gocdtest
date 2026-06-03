FROM python:3.11-alpine

WORKDIR /app

# Install dependencies required for certain Python packages if needed
# RUN apk add --no-cache gcc musl-dev linux-headers

COPY . .

RUN pip install --no-cache-dir flask

EXPOSE 5000

CMD ["python", "app.py"]
