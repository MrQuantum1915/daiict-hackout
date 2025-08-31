import "./globals.css";


export const metadata = {
  title: "Server",
  description: "server for community mongroove watch",
};

export default function RootLayout({ children }) {
  return (
    <html lang="en">
      <body>
        {children}
      </body>
    </html>
  );
}
